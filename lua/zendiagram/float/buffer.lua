---@class ZendiagramBuffer
local Buffer = {}

local _api = vim.api

---Create a new diagnostic buffer with the given lines
---@param lines string[] Lines to populate the buffer with
---@return number buffer Buffer handle
function Buffer.create_diagnostic_buffer(lines)
    local buf = _api.nvim_create_buf(false, true)

    -- Set buffer content
    _api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Set buffer options
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"

    -- Set buffer name
    _api.nvim_buf_set_name(buf, "[Diagnostics]")

    return buf
end

return Buffer
