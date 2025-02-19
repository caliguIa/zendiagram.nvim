---@class ZendiagramFloat
local Float = {}

local _window = require("zendiagram.float.window")
local _buffer = require("zendiagram.float.buffer")
local _format = require("zendiagram.float.format")
local _api = vim.api
local _diagnostic_win = nil

---Get diagnostics for current line
---@return table[] diagnostics Array of diagnostic items
local function get_current_diagnostics()
    local line = vim.fn.line(".") - 1
    local bufnr = _api.nvim_get_current_buf()
    return vim.diagnostic.get(bufnr, { lnum = line })
end

---Open diagnostics window
function Float.open()
    -- Handle existing window
    if _diagnostic_win and _api.nvim_win_is_valid(_diagnostic_win) then
        _api.nvim_set_current_win(_diagnostic_win)
        return
    end

    local diagnostics = get_current_diagnostics()
    if #diagnostics == 0 then return end

    local lines, content = _format.format_diagnostics(diagnostics)
    local buf = _buffer.create_diagnostic_buffer(lines)

    local dimensions = _window.calculate_window_dimensions(lines, content)
    local win_opts = _window.create_window_options(dimensions)
    _diagnostic_win = _api.nvim_open_win(buf, false, win_opts)

    _window.set_window_options(_diagnostic_win)
    _window.setup_window_autocommands(_diagnostic_win, buf)
    _window.setup_window_keymaps(_diagnostic_win, buf)
end

---Close diagnostics window
function Float.close()
    if _diagnostic_win and _api.nvim_win_is_valid(_diagnostic_win) then
        _api.nvim_win_close(_diagnostic_win, true)
        _diagnostic_win = nil
    end
end

return Float
