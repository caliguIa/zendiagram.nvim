---@class ZendiagramUtils
local Utils = {}
local _api = vim.api

local _fn = vim.fn

---Wrap text to specified width
---@param text string Text to wrap
---@param width number Maximum width
---@return string[] Wrapped lines
function Utils.wrap_text(text, width)
    local lines = {}
    local line = ""

    for word in text:gmatch("%S+") do
        if #line + #word + 1 <= width then
            line = line .. (line == "" and "" or " ") .. word
        else
            table.insert(lines, line)
            line = word
        end
    end

    if line ~= "" then table.insert(lines, line) end

    return lines
end

---Calculate content width based on configuration
---@param content string Content to calculate width for
---@return number width The calculated width
function Utils.calculate_content_width(content)
    local config = require("zendiagram.config")
    local max_width = 0

    for line in content:gmatch("[^\n]+") do
        max_width = math.max(max_width, _fn.strdisplaywidth(line))
    end

    return math.max(config.min_width, math.min(max_width + 4, config.max_width))
end

---Apply highlighting to a line
---@param buf number Buffer handle
---@param ns number Namespace ID
---@param line_nr number Line number
---@param line table Line content with highlighting info
function Utils.apply_highlighting(buf, ns, line_nr, line)
    -- Base highlight for the line
    if line.hl then
        _api.nvim_buf_set_extmark(buf, ns, line_nr, 0, {
            hl_group = line.hl,
            end_col = #line.text,
            priority = 100,
        })
    end

    -- Apply keyword highlighting if present
    if line.keywords then
        for _, kw in ipairs(line.keywords) do
            if kw.pattern then
                local start_idx = line.text:find(kw.pattern)
                while start_idx do
                    -- Find the closing delimiter based on the opening one
                    local opening_char = line.text:sub(start_idx, start_idx)
                    local closing_char
                    if opening_char == "'" then
                        closing_char = "'"
                    elseif opening_char == "`" then
                        closing_char = "`"
                    elseif opening_char == '"' then
                        closing_char = '"'
                    elseif opening_char == "<" then
                        closing_char = ">"
                    elseif opening_char == "(" then
                        closing_char = ")"
                    elseif opening_char == "{" then
                        closing_char = "}"
                    elseif opening_char == "[" then
                        closing_char = "]"
                    end

                    local end_idx = line.text:find(closing_char, start_idx + 1)
                    if end_idx then
                        -- Add 1 to start_idx to skip the opening delimiter
                        _api.nvim_buf_set_extmark(buf, ns, line_nr, start_idx, {
                            end_col = end_idx - 1, -- Subtract 1 to exclude closing delimiter
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
end

return Utils
