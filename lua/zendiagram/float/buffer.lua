local Buffer = {}

local _api = vim.api

---Apply highlighting to a line
---@param buf number Buffer handle
---@param ns number Namespace ID
---@param line_nr number Line number
---@param line table Line content with highlighting info
local function apply_highlighting(buf, ns, line_nr, line)
    if line.hl then
        _api.nvim_buf_set_extmark(buf, ns, line_nr, 0, {
            line_hl_group = line.hl,
            priority = 100,
        })
    end

    -- Apply keyword highlighting if present
    if line.keywords then
        for _, kw in ipairs(line.keywords) do
            local start_idx = line.text:find(kw.pattern)
            while start_idx do
                local end_idx = line.text:find("[`']", start_idx + 1)
                if end_idx then
                    -- Add 1 to start_idx and subtract 1 from end_idx to exclude the quotes
                    _api.nvim_buf_set_extmark(buf, ns, line_nr, start_idx, {
                        end_col = end_idx - 1,
                        hl_group = kw.hl,
                        priority = 200,
                    })
                    start_idx = line.text:find(kw.pattern, end_idx + 1)
                else
                    break
                end
            end
        end
    end
end

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
        if type(line) == "table" then apply_highlighting(buf, ns, i - 1, line) end
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
