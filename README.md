# zendiagram.nvim

A minimal, good looking diagnostic float window for Neovim.

## Screenshots

<img src="https://github.com/caliguIa/zendiagram.nvim/blob/main/assets/demo_multi.png?raw=true" style="width: 45%"/> <img src="https://github.com/caliguIa/zendiagram.nvim/blob/main/assets/demo_single.png?raw=true" style="width: 45%"/>
<img src="https://github.com/caliguIa/zendiagram.nvim/blob/main/assets/demo_w_sources.png?raw=true" style="width: 90%"/>

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
    header = "Diagnostics", -- Float window title
    source = true, -- Whether to display diagnostic source
    relative = "line", -- "line"|"win" - What the float window's position is relative to
    anchor = "NE", -- When 'relative' is set to "win" this sets the position of the floating window
})
```

## Usage

zendiagram exposes a few ways to configure and use the plugin.
As the underlying api used is the `vim.diagnostic.open_float` the most convenient solution is to override the default function.
As the `vim.diagnostic.open_float` api is used, all the expected behaviours around focusing the window remain constant here.

```lua
require("zendiagram").setup()
vim.diagnostic.open_float = Zendiagram.open
-- or: vim.diagnostic.open_float = require("zendiagram").open()
-- or: vim.diagnostic.open_float = vim.cmd.Zendiagram('open')
vim.keymap.set(
    "n",
    "<Leader>e",
    vim.diagnostic.open_float,
    { silent = true, desc = "Open diagnostics float" }
)
```

The open command is the entry point, there are a few ways of accessing it:

- A user command:

```
:Zendiagram open
```

```lua
vim.cmd.Zendiagram('open')
```

- A lua function:

```lua
require("zendiagram").open()
```

- The Zendiagram global:

```lua
Zendiagram.open()
```

If you don't want to override the default `vim.diagnostic.open_float` you can use these functions in your keymaps or autocmds.

```lua
vim.keymap.set(
    "n",
    "<Leader>e",
    function()
        require('zendiagram').open()
        -- or: vim.cmd.Zendiagram('open')
        -- or: Zendiagram.open()
        -- or: vim.diagnostic.open_float() if you have overridden the default function
    end,
    { silent = true, desc = "Open diagnostics float" }
)
```

Similarly, you can use an autocmd to automatically open the diagnostics float when the cursor moves.

```lua
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    callback = function()
        require("zendiagram").open()
        -- or: vim.cmd.Zendiagram('open')
        -- or: Zendiagram.open()
        -- or: vim.diagnostic.open_float() if you have overridden the default function
    end,
})
```

Another option would be to override the default `vim.diagnostic.jump` keymaps like so:

```lua
vim.keymap.set({"n", "x"}, "]d", function ()
    vim.diagnostic.jump({ count = 1 })
    vim.schedule(function()
        require("zendiagram").open()
        -- or: vim.cmd.Zendiagram('open')
        -- or: Zendiagram.open()
        -- or: vim.diagnostic.open_float() if you have overridden the default function
    end)
end, { desc = "Jump to next diagnostic" })

vim.keymap.set({"n", "x"}, "[d", function ()
  vim.diagnostic.jump({ count = -1 })
  vim.schedule(function()
    require("zendiagram").open()
    -- or: vim.cmd.Zendiagram('open')
    -- or: Zendiagram.open()
    -- or: vim.diagnostic.open_float() if you have overridden the default function
  end)
end, { desc = "Jump to prev diagnostic" })
```
