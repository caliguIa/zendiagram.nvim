---@class ZendiagramFloat
local Float = {}

local _window = require("zendiagram.float.window")
local _buffer = require("zendiagram.float.buffer")
local _format = require("zendiagram.float.format")
local _api = vim.api

local _diagnostic_win = nil
local _last_manual_trigger = false

---Get diagnostics for current line
---@return table[] diagnostics Array of diagnostic items
local function get_current_diagnostics()
    local line = vim.fn.line(".") - 1
    local bufnr = _api.nvim_get_current_buf()
    return vim.diagnostic.get(bufnr, { lnum = line })
end

---@class ZendiagramOpenOptions
---@field focus boolean|nil Whether to focus the window (default: true)

---@param opts? {focus: boolean}
function Float.open(opts)
    opts = opts or { focus = true }

    local diagnostics = get_current_diagnostics()

    -- Close window if no diagnostics
    if #diagnostics == 0 then
        Float.close()
        _last_manual_trigger = false
        return
    end

    -- Handle existing window
    if _diagnostic_win and _api.nvim_win_is_valid(_diagnostic_win) then
        -- For manual triggers (opts.focus not explicitly set to false)
        if opts.focus ~= false then
            -- Only focus if this is the second manual trigger
            if _last_manual_trigger then
                _api.nvim_set_current_win(_diagnostic_win)
                return
            end
            _last_manual_trigger = true
        else
            _last_manual_trigger = false
        end

        -- Update existing window content
        local lines, content = _format.format_diagnostics(diagnostics)
        local buf = _api.nvim_win_get_buf(_diagnostic_win)

        vim.bo[buf].modifiable = true
        _api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].modifiable = false

        local dimensions = _window.calculate_window_dimensions(lines, content)
        local win_config = _window.create_window_options(dimensions)
        _api.nvim_win_set_config(_diagnostic_win, win_config)
        return
    end

    local lines, content = _format.format_diagnostics(diagnostics)
    local buf = _buffer.create_diagnostic_buffer(lines)

    local dimensions = _window.calculate_window_dimensions(lines, content)
    local win_opts = _window.create_window_options(dimensions)
    _diagnostic_win = _api.nvim_open_win(buf, false, win_opts) -- Never focus on initial creation

    _window.set_window_options(_diagnostic_win)
    _window.setup_window_autocommands(_diagnostic_win, buf, opts.focus)
    _window.setup_window_keymaps(_diagnostic_win, buf)

    _last_manual_trigger = opts.focus ~= false
end

function Float.close()
    if _diagnostic_win and _api.nvim_win_is_valid(_diagnostic_win) then
        _api.nvim_win_close(_diagnostic_win, true)
        _diagnostic_win = nil
    end
end

return Float
