---@class ZendiagramConfigPosition
---@field row number
---@field col_offset number

---@class ZendiagramHighlightGroups
---@field ZendiagramHeader string
---@field ZendiagramSeparator string
---@field ZendiagramText string
---@field ZendiagramKeyword string

---@class ZendiagramConfig
---@field header string|nil
---@field max_width number
---@field min_width number
---@field max_height number
---@field position ZendiagramConfigPosition
---@field highlights ZendiagramHighlightGroups
---@field border "single"|"double"|"rounded"|"shadow"|"none"

---@class ZendiagramConfigModule
---@field header string|nil
---@field max_width number
---@field min_width number
---@field max_height number
---@field position ZendiagramConfigPosition
---@field border "single"|"double"|"rounded"|"shadow"|"none"
---@field highlights ZendiagramHighlightGroups
---@field setup fun(opts: ZendiagramConfig|nil): ZendiagramConfig
local Config = {}

---@type ZendiagramConfig
local _config = {
    header = "Diagnostics",
    max_width = 50,
    min_width = 25,
    max_height = 10,
    border = "none",
    position = {
        row = 1,
        col_offset = 2,
    },
    highlights = {
        ZendiagramHeader = "Error",
        ZendiagramSeparator = "NonText",
        ZendiagramText = "Normal",
        ZendiagramKeyword = "Keyword",
    },
}

---@param opts table
---@return boolean is_valid
local function validate_config(opts)
    local ok = pcall(function()
        vim.validate({
            header = { opts.header, { "string", "nil" } },
            max_width = {
                opts.max_width,
                function(n) return n == nil or (type(n) == "number" and n > 0) end,
                "must be a positive number",
            },
            min_width = {
                opts.min_width,
                function(n) return n == nil or (type(n) == "number" and n > 0) end,
                "must be a positive number",
            },
            max_height = {
                opts.max_height,
                function(n) return n == nil or (type(n) == "number" and n > 0) end,
                "must be a positive number",
            },
            position = { opts.position, { "table", "nil" } },
            border = {
                opts.border,
                function(border)
                    return border == nil
                        or border == "single"
                        or border == "double"
                        or border == "rounded"
                        or border == "shadow"
                        or border == "none"
                end,
                'must be "single", "double", "rounded", "shadow" or "none"',
            },
            highlights = { opts.highlights, { "table", "string", "nil" } },
        })

        if opts.position then
            vim.validate({
                ["position.row"] = { opts.position.row, "number" },
                ["position.col_offset"] = { opts.position.col_offset, "number" },
            })
        end

        if opts.min_width and opts.max_width and opts.min_width > opts.max_width then
            error("min_width cannot be greater than max_width")
        end
    end)

    return ok
end

function Config.setup(opts)
    if opts then
        if not validate_config(opts) then
            vim.notify("Invalid Zendiagram configuration. Using default configuration.", vim.log.levels.WARN)
            return _config
        end
        _config = vim.tbl_deep_extend("force", _config, opts)
    end

    return _config
end

return setmetatable(Config, {
    __index = function(_, key) return _config[key] end,
})
