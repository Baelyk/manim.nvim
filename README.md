# manim.nvim

A small plugin that creates two commands to render Manim scenes:
- `ManimRender`: render a specified scene or all scenes (default) with specified quality
    - Accepts two args:
        - the scene name or `all scenes` (default)
        - the render quality, defaults to `l`: `[l|m|h|p|k]`
- `ManimRenderUnderCursor`: render the scene under the cursor with specified quality
    - Uses treesitter to find the scene name and then falls back to `ManimRender`
    - Accepts one arg:
        - the render quality, defaults to `l`: `[l|m|h|p|k]`

Example configuration using `lazy.nvim`:
```lua
	{
		"Baelyk/manim.nvim",
		ft = "python",
		config = function()
			require("manim")
			vim.keymap.set("n", "<leader>ll", vim.cmd.ManimRenderUnderCursor)
			vim.keymap.set("n", "<leader>lm", function() vim.cmd.ManimRenderUnderCursor("m") end)
			vim.keymap.set("n", "<leader>lh", function() vim.cmd.ManimRenderUnderCursor("h") end)
			vim.keymap.set("n", "<leader>la", vim.cmd.ManimRender)
		end
	}
```
