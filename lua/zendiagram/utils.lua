---@class ZendiagramUtils
local Utils = {}

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

return Utils
