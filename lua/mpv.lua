local M = {}

local socket_name = "/tmp/manim-nvim-mpv"

local _mpv = nil
local function spawn_mpv()
	if _mpv and not _mpv:is_closing() then
		return
	end

	-- Spawn mpv
	local command = { "mpv", "--loop", "--idle", "--input-ipc-server=" .. socket_name }
	local opts = { detach = false }
	local on_exit = function() end
	local mpv = vim.system(command, opts, on_exit)

	-- Kill mpv on neovim exit
	vim.schedule(function()
		vim.api.nvim_create_autocmd("VimLeavePre", {
			callback = function()
				mpv:kill("sigterm")
			end,
			desc = "manim.nvim: kill mpv (" .. mpv.pid .. ") on exit",
		})
	end)

	-- Set global mpv to point to this mpv
	_mpv = mpv
end

local _pipe = nil
local function get_pipe()
	if _pipe then
		if _pipe:is_writable() then
			local broken_pipe = false
			_pipe:write("\n", function(err)
				broken_pipe = err == "EPIPE"
				vim.uv.stop()
			end)
			vim.uv.run()
			if not broken_pipe then
				return _pipe
			end
		end
	end

	spawn_mpv()
	_pipe = assert(vim.uv.new_pipe(false))
	assert(_pipe:connect(socket_name))

	return _pipe
end

---@param command table<string> MPV command to execute, as string or table
---@return nil
local function send_command(command)
	local pipe = get_pipe()

	-- JSON command
	local command_json = vim.json.encode({ command = command })
	pipe:write(command_json .. "\n", function(write_err)
		assert(not write_err, write_err)
		vim.uv.stop()
	end)

	vim.uv.run()
end

function M.play_files(paths, quality)
	send_command({ "playlist-clear" })
	send_command({ "playlist-remove", "current" })
	for _, path in ipairs(paths) do
		send_command({ "loadfile", path, "append" })
	end
	send_command({ "playlist-play-index", "0" })
	send_command({ "set_property", "osd-playing-msg", "[" .. quality .. "] ${media-title}" })
	send_command({ "set_property", "title", "[" .. quality .. "] ${media-title} - manim.nvim mpv" })
end

return M
