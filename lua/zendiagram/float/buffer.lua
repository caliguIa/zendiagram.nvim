local Buffer = {}

local _lines = require("zendiagram.float.lines")

local _api = vim.api

---Create a new diagnostic buffer with the given lines
---@param formatted_lines table[] Lines with highlighting information
---@return number buffer Buffer handle
function Buffer.create_diagnostic_buffer(formatted_lines)
    local buf = _api.nvim_create_buf(false, true)

    local text_lines = _lines.to_text(formatted_lines)
    _api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)
    _lines.apply_highlights(buf, formatted_lines)

    _api.nvim_buf_set_name(buf, "ZendiagramFloat")
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false

    return buf
end

return Buffer
