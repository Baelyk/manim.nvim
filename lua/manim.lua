-- Returns a list of the scenes in the specified buffer
local function scenes_in_buf(bufnr)
	bufnr = bufnr or 0
	local buf_path = vim.api.nvim_buf_get_name(bufnr)
	-- Ensure this buffer has been parsed
	local parser = vim.treesitter.get_parser(bufnr)
	parser:parse()

	local children = parser:trees()[1]:root():iter_children()
	local scenes = {}

	for node in children do
		if node:type() == "class_definition" then
			local scene = vim.treesitter.get_node_text(node:field("name")[1], bufnr)
			table.insert(scenes, scene)
		end
	end

	return scenes
end

local function find(list, value)
	for index, list_value in ipairs(list) do
		if list_value == value then
			return index
		end
	end
	return nil
end

-- Render all scenes or a specified scene
vim.api.nvim_create_user_command("ManimRender", function(opts)
	-- Accept specified quality or default to low and validate
	local quality = opts.fargs[1] or "l"
	if not (quality == "l"
			or quality == "m"
			or quality == "h"
			or quality == "p"
			or quality == "k") then
		print("Error: Expected quality [l|m|h|p|k], not " .. quality)
		return
	end
	-- Get the current buffer path
	local current_buffer = 0
	local buf_path = vim.api.nvim_buf_get_name(current_buffer)
	-- Accept specified scene and validate or default to all scenes
	local scenes = scenes_in_buf(current_buffer)
	local scene = opts.fargs[2]
	if opts.fargs[1] then
		if find(scenes, scene) then
			scene = opts.fargs[2]
		else
			print("Unexpected scene " .. scene)
			return
		end
	else
		scene = "all scenes"
	end
	-- Run manim
	local on_exit = function(out)
		if out.code ~= 0 then
			print("Error: ", out.stdout)
		else
			print("Rendered " .. scene)
		end
	end
	local command = { "manim", "render", "--quality", quality, buf_path }
	if scene == "all scenes" then
		for _, s in ipairs(scenes) do
			table.insert(command, s)
		end
	else
		table.insert(command, scene)
	end
	vim.system(
		command, {}, on_exit
	)
	print("Rendering " .. scene .. "...")
end, {
	nargs = "*",
})

-- Render the scene under the cursor
vim.api.nvim_create_user_command("ManimRenderUnderCursor", function(opts)
	-- Ensure this buffer has been parsed
	local current_buffer = 0
	local parser = vim.treesitter.get_parser(current_buffer)
	parser:parse()
	-- Get the scene under the cursor by traversing up the tree looking for the first class
	local scene
	local node = vim.treesitter.get_node()
	while node do
		if node:type() == "class_definition" then
			scene = vim.treesitter.get_node_text(node:field("name")[1], current_buffer)
			break
		end
		node = node:parent()
	end
	if not scene then
		print("Scene not found")
		return
	end
	vim.cmd.ManimRender(opts.fargs[1] or "l", scene)
end, {
	nargs = "?",
	complete = function(_, _, _)
		return { "l", "m", "h", "p", "k" }
	end
})
