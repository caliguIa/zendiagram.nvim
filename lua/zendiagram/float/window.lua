---@class ZendiagramWindow
local Window = {}

local _api = vim.api
local _utils = require("zendiagram.utils")
local _lines = require("zendiagram.float.lines")
local _config = require("zendiagram.config")
local _augroup = _api.nvim_create_augroup("ZendiagramWindow", { clear = true })

---Calculate window dimensions based on content
---@param lines string[] Content lines
---@param content string Raw content
---@return table dimensions Window dimensions
function Window.calculate_window_dimensions(lines, content)
    local width = _utils.calculate_content_width(content)
    local height = math.min(#lines, _config.max_height)
    local position = _config.position

    return {
        width = width,
        height = height,
        row = position.row,
        col = vim.o.columns - width - position.col_offset,
    }
end

---Create window options based on dimensions
---@param dimensions table Window dimensions
---@return table Window options
function Window.create_window_options(dimensions)
    return {
        relative = "editor",
        width = dimensions.width,
        height = dimensions.height,
        row = dimensions.row,
        col = dimensions.col,
        style = "minimal",
        border = _config.border,
        focusable = true,
    }
end

---Set window options for the diagnostic window
---@param win number Window handle
function Window.set_window_options(win)
    vim.wo[win].wrap = true
    vim.wo[win].conceallevel = 2
    vim.wo[win].foldenable = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].winhighlight = "Normal:NormalFloat"
end

---Setup window autocommands
---@param win number Window handle
---@param buf number Buffer handle
---@param focus boolean Focus mode
function Window.setup_window_autocommands(win, buf, focus)
    _api.nvim_create_autocmd("BufLeave", {
        buffer = buf,
        group = _augroup,
        callback = function()
            if win and _api.nvim_win_is_valid(win) then
                _api.nvim_win_close(win, true)
                return true
            end
        end,
        once = true,
    })

    if focus then
        _api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = _augroup,
            callback = function()
                if win and _api.nvim_win_is_valid(win) and _api.nvim_get_current_win() ~= win then
                    _api.nvim_win_close(win, true)
                    return true
                end
            end,
            once = true,
        })
    end
end

---Setup window keymaps
---@param win number Window handle
---@param buf number Buffer handle
function Window.setup_window_keymaps(win, buf)
    vim.keymap.set("n", "q", function()
        if win and _api.nvim_win_is_valid(win) then _api.nvim_win_close(win, true) end
    end, { buffer = buf, nowait = true })
end

---Update existing window content and highlighting
---@param win number Window handle
---@param formatted_lines table[] Formatted lines with highlighting info
---@param content string Raw content for dimension calculation
function Window.update_window_content(win, formatted_lines, content)
    local buf = _api.nvim_win_get_buf(win)

    -- Update content and highlights
    local text_lines = _lines.to_text(formatted_lines)
    vim.bo[buf].modifiable = true
    _api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)
    vim.bo[buf].modifiable = false
    _lines.apply_highlights(buf, formatted_lines)

    -- Update window dimensions
    local dimensions = Window.calculate_window_dimensions(text_lines, content)
    local win_config = Window.create_window_options(dimensions)
    _api.nvim_win_set_config(win, win_config)
end

return Window
