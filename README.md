# vis-lint

Lint the currently open file in [Vis](https://github.com/martanne/vis)
and display the output in the message window.

## Installation

Clone the repo to `$VIS_PATH/plugins` and then its sufficient to include
the following in your `visrc.lua`:

	require("plugins/vis-lint")

See [Plugins](https://github.com/martanne/vis/wiki/Plugins) on the Vis
wiki for further details.

## Usage

The following functions and commands are exported:

| Name                 | Description                                      |
|----------------------|--------------------------------------------------|
| `lint`               | Run to lint the current file (range if selected) |
| `fix`                | Run to fix the current file (range if selected)  |
| `.lint(file, range)` | `lint` command accessible from Lua               |
| `.fix(file, range)`  | `fix` command accessible from Lua                |

For example type the following into the Vis command prompt:

	:lint

## Configuration

### Adding A Tool

Additional tools for fixing and linting can be added as follows:

	local lint = require("plugins/vis-lint")
	table.insert(lint.linters["python"], "pylint --from-stdin stdin_from_vis")
	table.insert(lint.linters["python"], "mypy /dev/stdin")

#### Tools must read from `stdin` and output to `stdout`!

Some programs, like the above examples, may need some non standard flags.
You can also try using `-` or `/dev/stdin` as the input parameter.

### Overriding The Defaults

The defaults can be also be overridden:

	lint.fixers["lua"] = { "cat" }

Note that an equivalent in this case is just:

	lint.fixers["lua"] = {}

### Adding New Filetypes

A new filetype can be added as follows (`awkfix` is a hypothetical
`awk` fixer):

	lint.fixers["awk"] = { "awkfix" }

Note: if a default doesn't exist feel free to submit a patch adding it!

### Running Fixers Before Writing

The fixers can be run before saving a file using Vis' events:

	vis.events.subscribe(vis.events.FILE_SAVE_PRE, lint.fix)

Note that if any fixer fails the file won't save (unless `:w!` was used).

### Silencing Logging Or Logging To File

The logging function is stored as a configuration variable and can be
modified as follows:

	lint.logger = function(str, level)
		if level == lint.log.INFO then
			vis:info(str)
		else
			local fp = io.open("log.txt", "*a")
			fp:write(str .. "\n")
			fp:close()
		end
	end

The sent message levels are `INFO`, `OUTPUT`, and `ERROR`.
