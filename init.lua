local lint = {}

lint.linters = {}
lint.linters["bash"] = {"shellcheck -"}
lint.linters["json"] = {"jq"}
lint.linters["lua"] = {"luacheck --no-color -"}
lint.linters["man"] = {"mandoc -T lint"}
lint.linters["python"] = {"black --check -", "isort --check -"}
lint.linters["rust"] = {"rustfmt --check", "clippy-driver -"}

lint.fixers = {}
lint.fixers["json"] = {"jq -c"}
lint.fixers["python"] = {"black -", "isort -"}
lint.fixers["rust"] = {"rustfmt"}

-- Clear vis:message window before running?
run_actions_on_file = function(action, actions, file, modify)
	local cmds = actions[vis.win.syntax]
	if cmds == nil or #cmds == 0 then
		vis:info(action
			.. " not defined for vis.win.syntax = "
			.. (vis.win.syntax or "undefined")
			.. " in file "
			.. (file.name or "unnamed file"))
		return
	end
	-- Print this for clarity and separate different outputs in the vis:message buffer
	local header = "--- " .. action .. ": "
	vis:message(header .. "running " .. action .. " (" .. os.date() .. ")")
	local all_succeeded = true
	for i, cmd in ipairs(cmds) do
		vis:message(header .. "piping "
			.. (file.name or "unnamed file")
			.. " to `" .. cmd .. "`")
		local status, ostr, estr = vis:pipe(file, {start = 0, finish = file.size}, cmd)

		if ostr ~= nil or estr ~= nil then
			if (modify and ostr) then
				local pos = vis.win.selection.pos
				file:delete(0, file.size)
				file:insert(0, ostr)
				vis.win.selection.pos = pos
			else
				if ostr then vis:message(ostr) end
			end
			if estr then vis:message(estr) end
			vis:redraw()
		end

		if status then
			all_succeeded = false
			-- Exit early if any fixer fails as indicated by the exit status
			if modify then
				vis:message("Fixer failed with status code " .. status)
				return false
			end
		end
	end
	vis:message(header .. "done")
	return all_succeeded
end

vis:command_register("lint", function(argv, force, win, selection, range)
	return run_actions_on_file("linters", lint.linters, win.file, false)
end, "Lint the current file and display output in the message window")

vis:command_register("fix", function(argv, force, win, selection, range)
	return run_actions_on_file("fixers", lint.fixers, win.file, true)
end, "Pipe the current file through defined fixers. Modifies the buffer.")

return lint
