# Zendiagrams.nvim

A minimal, focused diagnostic float window for Neovim.

## Features

- Clean, distraction-free diagnostic display
- Dynamic window sizing based on content
- Markdown formatting with syntax highlighting
- Focused mode with vim-style navigation
- Automatic text wrapping for long diagnostics

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    'yourusername/zendiagrams.nvim',
    config = function()
        require('zendiagrams').setup({
              -- Optional configuration
        })
    end
}
```

## Configuration

```lua
require('zendiagrams').setup({
    max_width = 50, -- Maximum window width
    min_width = 25, -- Minimum window width
    max_height = 10, -- Maximum window height
    position = {
        row = 1, -- Row position from top
        col_offset = 2 -- Column offset from right
    },
    mapping = '<Leader>e' -- Key mapping to show diagnostics
})
```

## Usage

- Press <Leader>e (or your configured mapping) to show diagnostics for the current line
- Press it again to focus the window
- Use q to close the window
- Window automatically closes when focus is lost or cursor moves
