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

lint.log = {}
lint.log.INFO = 1
lint.log.ERROR = 2
lint.log.OUTPUT = 3

lint.logger = function(str, level)
	if level == lint.log.INFO then
		vis:info(str)
	else
		vis:message(str)
	end
end

local run_on_file = function(cmd, file, range, modify)
	if range == nil or range.finish - range.finish <= 1 then
		range = {start = 0, finish = file.size}
	end
	local ret, ostr, estr = vis:pipe(file, range, cmd)
	if ostr ~= nil or estr ~= nil then
		if (modify and ostr) then
			local pos = vis.win.selection.pos
			file:delete(range.start, range.finish)
			file:insert(range.start, ostr)
			vis.win.selection.pos = pos
		else
			if ostr then lint.logger(ostr, lint.log.OUTPUT) end
		end
		if estr then lint.logger(estr, lint.log.ERROR) end
		vis:redraw()
	end
	return ret
end

local run_actions_on_file = function(actions, file, range, modify)
	local cmds = actions[vis.win.syntax]
	if cmds == nil or #cmds == 0 then
		lint.logger("vis-lint: action not defined for vis.win.syntax = "
			.. (vis.win.syntax or "undefined"), lint.log.INFO)
		return
	end
	-- print this to separate different outputs in the message buffer
	local prefix = "--- "
	lint.logger(prefix .. "vis-lint: (" .. os.date() .. ")")
	local all_succeeded = true
	for _, cmd in ipairs(cmds) do
		lint.logger(prefix .. "piping "
			.. (file.name or "buffer")
			.. (range and "<" .. range.start ..  "," .. range.finish .. ">" or "")
			.. " to `" .. cmd .. "`")
		local ret = run_on_file(cmd, file, range, modify)
		if ret ~= 0 then
			all_succeeded = false
			-- exit early if modify was specified
			if modify then
				lint.logger("Command failed with exit code: " .. ret, lint.log.ERROR)
				return false
			end
		end
	end
	lint.logger(prefix .. "done")
	return all_succeeded
end

lint.lint = function(file, range)
	return run_actions_on_file(lint.linters, file, range)
end

lint.fix = function(file, range)
	return run_actions_on_file(lint.fixers, file, range, true)
end

vis:command_register("lint", function(argv, force, win, selection, range)
	return lint.lint(win.file, range)
end, "Lint the current file and display output in the message window")

vis:command_register("fix", function(argv, force, win, selection, range)
	return lint.fix(win.file, range)
end, "Pipe the current file through defined fixers. Modifies the buffer.")

return lint
