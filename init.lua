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

local run_on_file = function(cmd, file, modify)
	local ret, ostr, estr = vis:pipe(file, {start = 0, finish = file.size}, cmd)
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
	return ret
end

-- Clear vis:message window before running?
local run_actions_on_file = function(action, actions, file, modify)
	local cmds = actions[vis.win.syntax]
	if cmds == nil or #cmds == 0 then
		vis:info(action
			.. " not defined for vis.win.syntax = "
			.. (vis.win.syntax or "undefined")
			.. " in file "
			.. (file.name or "unnamed file"))
		return
	end
	-- print this to separate different outputs in the message buffer
	local prefix = "--- vis-lint: "
	vis:message(prefix .. "running " .. action .. " (" .. os.date() .. ")")
	local all_succeeded = true
	for _, cmd in ipairs(cmds) do
		vis:message(prefix .. "piping "
			.. (file.name or "buffer")
			.. " to `" .. cmd .. "`")
		local ret = run_on_file(cmd, file, modify)
		if ret ~= 0 then
			all_succeeded = false
			-- exit early if modify was specified
			if modify then
				vis:message("Command failed with exit code: " .. ret)
				return false
			end
		end
	end
	vis:message(prefix .. "done")
	return all_succeeded
end

lint.lint = function(file)
	return run_actions_on_file("linter", lint.linters, file, false)
end

lint.fix = function(file)
	return run_actions_on_file("fixer", lint.fixers, file, true)
end

vis:command_register("lint", function(argv, force, win, selection, range)
	return lint.lint(win.file)
end, "Lint the current file and display output in the message window")

vis:command_register("fix", function(argv, force, win, selection, range)
	return lint.fix(win.file)
end, "Pipe the current file through defined fixers. Modifies the buffer.")

return lint
