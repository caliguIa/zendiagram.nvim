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
    opts = vim.tbl_extend("force", { focus = true }, opts)

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
        local formatted_lines, content = _format.format_diagnostics(diagnostics)
        _window.update_window_content(_diagnostic_win, formatted_lines, content)
        return
    end

    local lines, content = _format.format_diagnostics(diagnostics)
    local buf = _buffer.create_diagnostic_buffer(lines)

    local dimensions = _window.calculate_window_dimensions(lines, content)
    local win_opts = _window.create_window_options(dimensions)
    _diagnostic_win = _api.nvim_open_win(buf, false, win_opts)

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
