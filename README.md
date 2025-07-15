# manim.nvim

A small plugin that creates commands to render Manim scenes. There are two families of commands:
- `ManimRender`: render a specified scene or all (default)
    - Accepts two args:
        - the scene name or `all` (default)
- `ManimRenderUnderCursor`: render the scene under the cursor with specified quality
    - Uses treesitter to find the scene name
There exist variants of these two for each quality level: `Low`, `Medium`, `High`, `1440`, and `4k`.

Example configuration using `lazy.nvim`:
```lua
{
    "Baelyk/manim.nvim",
    name = "manim.nvim",
    ft = "python",
    config = true,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    keys = {
        {
            "<leader>ll",
            vim.cmd.ManimRenderUnderCursorLow,
            desc = "Render current Manim scene in low quality",
        },
        {
            "<leader>lm",
            vim.cmd.ManimRenderUnderCursorMedium,
            desc = "Render current Manim scene in medium quality",
        },
        {
            "<leader>lh",
            vim.cmd.ManimRenderUnderCursorHigh,
            desc = "Render current Manim scene in high quality",
        },
        {
            "<leader>la",
            vim.cmd.ManimRenderLow,
            desc = "Render all Manim scenes in low quality",
        },
    },
},
```
