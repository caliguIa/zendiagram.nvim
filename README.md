# zendiagram.nvim

A minimal, good looking diagnostic float window for Neovim.

## Features

- Clean, distraction-free diagnostic floating window
- Markdown formatting with syntax highlighting for clearer errors

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
    header = "## Diagnostics", -- Header text
    style = "default", -- Float window style - 'default' | 'compact'
    max_width = 50, -- The maximum width of the float window
    min_width = 25, -- The minimum width of the float window
    max_height = 10, -- The maximum height of the float window
    position = {
        row = 1, -- The offset from the top of the screen
        col_offset = 2, -- The offset from the right of the screen
    },
})
```

## Usage

zendiagram exposes two functions to the user:

- `open`: opens the diagnostics float window, and if the window is already open, focuses it
- `close`: closes the diagnostics float window (you are likely to not need this)

It's advised to use the open function in a keymap, like so:

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

Due to the markdown formatting, it is strongly advised to use a markdown rendering plugin such as
[render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) to really see the benefits of zendiagram.

I may explore non-markdown formatting in the future, but for now, markdown is it.
