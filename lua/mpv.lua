local pipe = assert(vim.uv.new_pipe(true))
assert(pipe:connect("/tmp/foo"))
local command = {
	command = {
		"show-text",
		"Hello world!",
	},
}
local command_json = vim.json.encode(command)
pipe:write(command_json .. "\n")
