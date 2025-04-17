local Lines = {}

local _api = vim.api

---Convert formatted lines to plain text lines
---@param formatted_lines table[] Lines with highlighting information
---@return string[] text_lines
function Lines.to_text(formatted_lines)
    return vim.tbl_map(function(line) return type(line) == "table" and line.text or line end, formatted_lines)
end

---Apply highlights to a buffer
---@param buf number Buffer handle
---@param formatted_lines table[] Lines with highlighting information
function Lines.apply_highlights(buf, formatted_lines)
    local ns = _api.nvim_create_namespace("zendiagram")
    _api.nvim_buf_clear_namespace(buf, ns, 0, -1)

    for i, line in ipairs(formatted_lines) do
        if type(line) == "table" then Lines.apply_line_highlight(buf, ns, i - 1, line) end
    end
end

---Apply highlighting to a single line
---@param buf number Buffer handle
---@param ns number Namespace ID
---@param line_nr number Line number
---@param line table Line content with highlighting info
function Lines.apply_line_highlight(buf, ns, line_nr, line)
    if line.hl then
        _api.nvim_buf_set_extmark(buf, ns, line_nr, 0, {
            hl_group = line.hl,
            end_col = #line.text,
            priority = 100,
        })
    end

    if line.source_highlight then
        _api.nvim_buf_set_extmark(buf, ns, line_nr, line.source_highlight.start_col, {
            hl_group = line.source_highlight.hl,
            end_col = line.source_highlight.end_col,
            priority = 150,
        })
    end

    if line.keywords then Lines.apply_keyword_highlights(buf, ns, line_nr, line) end
end

local DELIMITERS = {
    ["'"] = "'",
    ["`"] = "`",
    ['"'] = '"',
    ["<"] = ">",
    ["("] = ")",
    ["{"] = "}",
    ["["] = "]",
}

---Apply keyword highlights to a line
---@param buf number Buffer handle
---@param ns number Namespace ID
---@param line_nr number Line number
---@param line table Line content with highlighting info
function Lines.apply_keyword_highlights(buf, ns, line_nr, line)
    for _, kw in ipairs(line.keywords) do
        if kw.pattern then
            local start_idx = line.text:find(kw.pattern)
            while start_idx do
                local opening_char = line.text:sub(start_idx, start_idx)
                local closing_char = DELIMITERS[opening_char]

                local end_idx = line.text:find(closing_char, start_idx + 1)
                if end_idx then
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

return Lines
