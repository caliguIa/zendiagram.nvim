local Buffer = {}

local _utils = require("zendiagram.utils")

local _api = vim.api

---Create a new diagnostic buffer with the given lines
---@param formatted_lines table[] Lines with highlighting information
---@return number buffer Buffer handle
function Buffer.create_diagnostic_buffer(formatted_lines)
    local buf = _api.nvim_create_buf(false, true)
    local ns = _api.nvim_create_namespace("zendiagram")

    local text_lines = vim.tbl_map(
        function(line) return type(line) == "table" and line.text or line end,
        formatted_lines
    )

    _api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)

    for i, line in ipairs(formatted_lines) do
        if type(line) == "table" then _utils.apply_highlighting(buf, ns, i - 1, line) end
    end

    _api.nvim_buf_set_name(buf, "ZendiagramFloat")
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false

    return buf
end

return Buffer
