---@alias Quality "l"|"m"|"h"|"p"|"k"
local quality_command_names = { l = "Low", m = "Medium", h = "High", p = "1440", k = "4k" }
local qualities = { l = "480p15", m = "720p30", h = "1080p60", p = "1440p60", k = "2880p60" }

---Wrapper around `vim.notify`
---@param msg string
---@param level? integer
---@param key? string replace previous notification with this key
local function notify(msg, level, key)
	vim.notify(msg, level, { key = "manim.nvim-" .. (key or ""), group = "manim.nvim", annote = "manim.nvim" })
end

--- Ensure this buffer has been parsed, and get the tree
---@param bufnr? integer the buffer for which to get the parser, defaults to the current buffer
local function parse(bufnr)
	local parser = vim.treesitter.get_parser(bufnr)
	if parser then
		return (parser:parse() or {})[1]
	end
	return nil
end

---@return string|nil # the scene under the cursor, if there was one
local function scene_under_cursor()
	-- Ensure this buffer has been parsed
	parse()
	-- Get the scene under the cursor by traversing up the tree looking for the first class
	local scene = nil
	local node = vim.treesitter.get_node()
	while node do
		if node:type() == "class_definition" then
			scene = vim.treesitter.get_node_text(node:field("name")[1], 0)
			break
		end
		node = node:parent()
	end
	return scene
end

---Returns a list of the scenes in the specified buffer
---@param bufnr? integer the buffer for which to get the parser, defaults to the current buffer
local function scenes_in_buf(bufnr)
	bufnr = bufnr or 0
	local parser = parse(bufnr)
	if not parser then
		return
	end

	local children = parser:root():iter_children()
	---@type table<string>
	local scenes = {}

	for node in children do
		if node:type() == "class_definition" then
			local scene = vim.treesitter.get_node_text(node:field("name")[1], bufnr)
			table.insert(scenes, scene)
		end
	end

	return scenes
end

local function scene_paths(file_name, quality, scenes, media_dir)
	if not media_dir then
		media_dir = "media"
	end
	local paths = {}
	for _, scene in ipairs(scenes) do
		table.insert(paths, media_dir .. "/videos/" .. file_name .. "/" .. qualities[quality] .. "/" .. scene .. ".mp4")
	end
	return paths
end

local function preview(paths, quality)
	local mpv = require("mpv")
	mpv.play_files(paths, qualities[quality])
end

---Run `manim render`
---@param quality Quality
---@param scenes table<string>
local function render(quality, scenes)
	local current_buffer = 0
	local path = vim.api.nvim_buf_get_name(current_buffer)

	---@type string
	local scene_name
	if #scenes == 1 then
		scene_name = scenes[1]
	else
		scene_name = #scenes .. " scenes"
	end

	local file_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t:r")
	local on_exit = function(out)
		if out.code ~= 0 then
			notify(out.stdout, vim.log.levels.ERROR)
		else
			notify("Rendered " .. scene_name, nil, "render")
			local paths = scene_paths(file_name, quality, scenes)
			preview(paths, quality)
		end
	end

	local command = { "manim", "render", "--quality", quality, path }
	for _, s in ipairs(scenes) do
		table.insert(command, s)
	end
	vim.system(command, {}, on_exit)

	notify("Rendering " .. scene_name .. "...", nil, "render")
end

---Completion options for the ManimRender<Quality> commands
local manim_render_completion = {
	nargs = "?",
	complete = function()
		local completions = scenes_in_buf()
		if not completions then
			return { "all" }
		end
		table.insert(completions, "all")
		return completions
	end,
}

---Render all scenes or a specified scene
---@param quality Quality
local function manim_render(quality)
	---@param opts vim.api.keyset.create_user_command.command_args
	return function(opts)
		-- Accept specified scene and validate or default to all scenes
		local buf_scenes = scenes_in_buf()
		if not buf_scenes then
			notify("Unable to get scenes in the buffer", vim.log.levels.ERROR)
			return
		end
		local scenes
		if opts.fargs[2] then
			if vim.tbl_contains(scenes, opts.fargs[2]) then
				scenes = { opts.fargs[2] }
			else
				notify("Unexpected scene " .. opts.fargs[2], vim.log.levels.ERROR)
				return
			end
		else
			scenes = buf_scenes
		end

		-- Run manim
		render(quality, scenes)
	end
end

---Render the scene under the cursor
---@param quality Quality
local function manim_render_under_cursor(quality)
	return function()
		-- Get the scene under the cursor
		local scene = scene_under_cursor()
		if not scene then
			notify("No scene under cursor", vim.log.levels.WARN)
			return
		end

		render(quality, { scene })
	end
end

local M = {}

function M.setup()
	-- Render all scenes or a specified scene
	for quality, name in pairs(quality_command_names) do
		vim.api.nvim_create_user_command("ManimRender" .. name, manim_render(quality), manim_render_completion)
	end

	-- Render the scene under the cursor
	for quality, name in pairs(quality_command_names) do
		vim.api.nvim_create_user_command("ManimRenderUnderCursor" .. name, manim_render_under_cursor(quality), {})
	end
end

return M
