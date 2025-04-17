local Format = {}

local _utils = require("zendiagram.utils")
local _config = require("zendiagram.config")

---Create a separator line based on window width
---@param width number Width of the separator
---@return string
local function create_separator(width) return string.rep("─", width - 3) end

---Calculate required width for all diagnostics
---@param diagnostics table[] Array of diagnostic items
---@return number width The required width
local function calculate_required_width(diagnostics)
    local max_width = 0
    for _, diagnostic in ipairs(diagnostics) do
        max_width = math.max(max_width, #diagnostic.message + 5) -- Add padding
    end
    return math.min(max_width, _config.max_width)
end

---Wrap and format a single diagnostic message
---@param message string The diagnostic message to format
---@param width number Maximum width for content
---@return string[] lines Formatted lines
---@return string longest_line The longest line in the content
local function wrap_diagnostic_message(message, width)
    local lines = {}
    local longest_line = ""

    local wrapped_lines = _utils.wrap_text(message, width - 2)
    for _, line in ipairs(wrapped_lines) do
        table.insert(lines, line)
        if #line > #longest_line then longest_line = line end
    end

    return lines, longest_line
end

---Format all diagnostics
---@param diagnostics table[] Array of diagnostic items
---@return table[] lines Formatted lines with highlighting
---@return string longest_message The longest message
function Format.format_diagnostics(diagnostics)
    local lines = {}
    local width = calculate_required_width(diagnostics)
    local longest_message = ""

    local header = _config.header
    if header then
        table.insert(lines, {
            text = " " .. header,
            hl = "ZendiagramHeader", -- New highlight group for header line
        })
    end

    for i, diagnostic in ipairs(diagnostics) do
        if i > 1 then
            table.insert(lines, {
                text = " " .. create_separator(width),
                hl = "ZendiagramSeparator",
            })
        end

        local message = diagnostic.message
        local source = diagnostic.source
        if _config.source and source then
            if source:sub(-1, -1) == "." then source = source:sub(1, -2) end
            message = source .. ": " .. message
        end

        local message_lines, message_longest = wrap_diagnostic_message(message, width)
        longest_message = #message_longest > #longest_message and message_longest or longest_message

        for i, line in ipairs(message_lines) do
            local formatted_line = {
                text = " " .. line,
                hl = "ZendiagramText",
                keywords = {
                    { pattern = "'[^']+'", hl = "ZendiagramKeyword" },
                    { pattern = "`[^`]+`", hl = "ZendiagramKeyword" },
                    { pattern = '"[^"]+"', hl = "ZendiagramKeyword" },
                    { pattern = "<[^>]+>", hl = "ZendiagramKeyword" },
                    { pattern = "%([^%)]+%)", hl = "ZendiagramKeyword" },
                    { pattern = "{[^}]+}", hl = "ZendiagramKeyword" },
                    { pattern = "%[[^%]]+%]", hl = "ZendiagramKeyword" },
                },
                source_highlight = nil,
            }

            if i == 1 and _config.source and source then
                formatted_line.source_highlight = {
                    start_col = 1,
                    end_col = #source + 1, -- Include the colon
                    hl = "ZendiagramSource",
                }
            end

            table.insert(lines, formatted_line)
        end
    end

    return lines, longest_message
end

return Format
