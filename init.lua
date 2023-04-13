vis:command_register("lint", function()
	local linters = {}
	linters["bash"] = "shellcheck -"

	local cmd = linters[vis.win.syntax]
	if cmd == nil then
		vis:info(vis.win.syntax .. ": linter not defined")
		return false
	end

	local file = vis.win.file
	local _, ostr, estr = vis:pipe(file, {start = 0, finish = file.size},
	                               cmd .. " " .. file.name)
	if estr then
		vis:message(estr)
		return false
	end
	vis:message(ostr)
	return true
end, "Lint the current file and display output in the message window")
