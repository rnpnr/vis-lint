linters = {}
linters["bash"] = {"shellcheck -"}
linters["json"] = {"jq"}
linters["lua"] = {"luacheck --no-color -"}
linters["man"] = {"mandoc -T lint"}
linters["python"] = {"ruff", "mypy --strict"}
linters["rust"] = {"cargo check", "cargo clippy"}

fixers = {}
fixers["json"] = {"jq -c"}
fixers["python"] = {"black", "isort", "ruff --fix"}
fixers["rust"] = {"cargo fmt", "cargo clippy --fix"}

-- Clear vis:message window before running?
run_actions_on_file = function(action, actions, file, modify)
	local cmds = actions[vis.win.syntax]
	if cmds == nil or #cmds == 0 then
		vis:info(action  .. " not defined for " .. vis.win.syntax)
		return false
	end
	for i, cmd in ipairs(cmds) do
		vis:message("$ " .. cmd .. "\n")
		local _, ostr, estr = vis:pipe(file, {start = 0, finish = file.size}, cmd)

		if ostr == nil and estr == nil then
			vis:message("[no output]")
		else
			if (modify and ostr) then
				local pos = vis.win.selection.pos
				file:delete(0, file.size)
				file:insert(0, ostr)
				vis.win.selection.pos = pos
			else
				vis:message(ostr or "")
			end
			vis:message(estr or "")
		end
		vis:message("\n")

		if estr then
			return false
		end
	end
	return true
end

vis:command_register("lint", function(argv, force, win, selection, range)
	return run_actions_on_file('linters', linters, win.file, false)
end, "Lint the current file and display output in the message window")

vis:command_register("fix", function(argv, force, win, selection, range)
	return run_actions_on_file('fixers', fixers, win.file, true)
end, "Pipe the current file through defined fixers. Modifies the buffer.")
