---@class ZendiagramFormat
local Format = {}

local _utils = require("zendiagram.utils")
local _config = require("zendiagram.config")

---Create a separator line based on window width
---@param width number Width of the separator
---@return string
local function create_separator(width) return string.format(" %s", string.rep("─", width - 3)) end

---Format diagnostic content with proper wrapping
---@param diagnostic table Diagnostic item to format
---@param width number Maximum width for content
---@return string[] lines Formatted lines
---@return string longest_line The longest line in the content
local function format_diagnostic_content(diagnostic, width)
    local lines = {}
    local longest_line = ""

    local wrapped_lines = _utils.wrap_text(diagnostic.message, width - 5)
    for _, line in ipairs(wrapped_lines) do
        local formatted_line = string.format(" %s", line)
        table.insert(lines, formatted_line)
        if #line > #longest_line then longest_line = line end
    end

    return lines, longest_line
end

---Format diagnostics in default style
---@param diagnostics table[] Array of diagnostic items
---@param width number Maximum width for content
---@return string[] lines Formatted lines
---@return string longest_message The longest message
local function format_default_style(diagnostics, width)
    local lines = {}
    local longest_message = ""
    local ft = vim.bo.filetype

    for i, diagnostic in ipairs(diagnostics) do
        if i > 1 then table.insert(lines, "---") end

        table.insert(lines, string.format(" ```%s", ft))
        local content_lines, content_longest = format_diagnostic_content(diagnostic, width)
        vim.list_extend(lines, content_lines)
        longest_message = #content_longest > #longest_message and content_longest or longest_message
        table.insert(lines, " ```")
    end

    return lines, longest_message
end

---Format diagnostics in compact style
---@param diagnostics table[] Array of diagnostic items
---@param width number Maximum width for content
---@return string[] lines Formatted lines
---@return string longest_message The longest message
local function format_compact_style(diagnostics, width)
    local lines = {}
    local longest_message = ""
    local ft = vim.bo.filetype

    table.insert(lines, string.format(" ```%s", ft))

    for i, diagnostic in ipairs(diagnostics) do
        if i > 1 then table.insert(lines, create_separator(width)) end

        local content_lines, content_longest = format_diagnostic_content(diagnostic, width)
        vim.list_extend(lines, content_lines)
        longest_message = #content_longest > #longest_message and content_longest or longest_message
    end

    table.insert(lines, " ```")

    return lines, longest_message
end

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

---Format diagnostics based on configuration
---@param diagnostics table[] Array of diagnostic items
---@return string[] lines Formatted lines
---@return string longest_message The longest message
function Format.format_diagnostics(diagnostics)
    local lines = {}

    -- Calculate the required width first
    local width = calculate_required_width(diagnostics)

    -- Add header if configured
    local header = _config.header
    if header then table.insert(lines, header) end

    -- Format based on style using the calculated width
    local formatted_lines, longest_message
    if _config.style == "compact" then
        formatted_lines, longest_message = format_compact_style(diagnostics, width)
    else
        formatted_lines, longest_message = format_default_style(diagnostics, width)
    end

    vim.list_extend(lines, formatted_lines)
    return lines, longest_message
end

return Format
