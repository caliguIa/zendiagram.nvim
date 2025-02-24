# zendiagram.nvim

A minimal, good looking diagnostic float window for Neovim.

## Demo

<details>
  <summary>Using default style</summary>

Multiple diagnostics:
<img src="https://github.com/caliguIa/zendiagram.nvim/blob/main/assets/default_multi.png?raw=true" style="width: 100%"/>

</details>

<details>
  <summary>Using compact style</summary>

Multiple diagnostics:
<img src="https://github.com/caliguIa/zendiagram.nvim/blob/main/assets/compact_multi.png?raw=true" style="width: 100%"/>

Single diagnostic:
<img src="https://github.com/caliguIa/zendiagram.nvim/blob/main/assets/compact_single.png?raw=true" style="width: 100%"/>

</details>

## Installation

<details>
  <summary>mini.deps</summary>

Using [mini.deps](https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-deps.md):

```lua
add("caliguIa/zendiagram.nvim")
require('zendiagram').setup()
```

</details>

<details>
  <summary>lazy.nvim</summary>

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
    "caliguIa/zendiagram.nvim",
    opts = {},
}
```

</details>

## Configuration

```lua
require('zendiagram').setup({
    -- Below are the default values
    header = "Diagnostics", -- Header text
    max_width = 50, -- The maximum width of the float window
    min_width = 25, -- The minimum width of the float window
    max_height = 10, -- The maximum height of the float window
    border = "none", -- The border style of the float window
    position = {
        row = 1, -- The offset from the top of the screen
        col_offset = 2, -- The offset from the right of the screen
    },
    highlights = { -- Highlight groups for each section of the float
        ZendiagramHeader = "Error", -- Accepts a highlight group name or a table of highlight group opts
        ZendiagramSeparator = "NonText",
        ZendiagramText = "Normal",
        ZendiagramKeyword = "Keyword",
    },

})
```

## Usage

zendiagram exposes two functions to the user:

- `open`: opens the diagnostics float window, and if the window is already open, focuses it
- `close`: closes the diagnostics float window (you are likely to not need this)

You can use these functions in your keymaps, or in autocmds to automatically open the diagnostics float when the cursor moves.

```lua
vim.keymap.set(
    "n",
    "<Leader>e",
    function() require('zendiagram').open() end,
    { silent = true, desc = "Open diagnostics float" }
)
```

With the above keymap set usage would look like so:

- Press `<Leader>e` (or your configured mapping) to show diagnostics for the current line
- Press it again to focus the float
- Use `q` to close the float
- The float automatically closes when focus is lost, or if the float is not focused; this occurs when the cursor moves

Similarly, you can use an autocmd to automatically open the diagnostics float when the cursor moves.
Be sure to set `focus = false` to prevent the float from stealing focus on cursor move.

```lua
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    callback = function() require("zendiagram").open({ focus = false }) end,
})
```

Another option would be to override the default `vim.diagnostic.jump` keymaps like so:

```lua
vim.keymap.set({"n", "x"}, "]d", function ()
  vim.diagnostic.jump({count = 1})
  vim.schedule(function()
    require("zendiagram").open()
  end)
end,
{ desc = "Jump to next diagnostic" })

vim.keymap.set({"n", "x"}, "[d", function ()
  vim.diagnostic.jump({count = -1})
  vim.schedule(function()
    require("zendiagram").open()
  end)
end,
{ desc = "Jump to prev diagnostic" })
```
