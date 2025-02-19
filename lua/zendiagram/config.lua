---@class ZendiagramConfigPosition
---@field row number
---@field col_offset number

---@class ZendiagramConfig
---@field header string|nil
---@field style "default"|"compact"
---@field max_width number
---@field min_width number
---@field max_height number
---@field position ZendiagramConfigPosition

---@class ZendiagramConfigModule
---@field header string|nil
---@field style "default"|"compact"
---@field max_width number
---@field min_width number
---@field max_height number
---@field position ZendiagramConfigPosition
---@field setup fun(opts: ZendiagramConfig|nil): ZendiagramConfig
local Config = {}

---@type ZendiagramConfig
local _config = {
    header = "## Diagnostics",
    style = "default",
    max_width = 50,
    min_width = 25,
    max_height = 10,
    position = {
        row = 1,
        col_offset = 2,
    },
}

---Validate configuration options
---@param opts table
---@return boolean is_valid
local function validate_config(opts)
    -- Wrap validation in pcall to catch any errors
    local ok = pcall(function()
        vim.validate({
            header = { opts.header, { "string", "nil" } },
            style = {
                opts.style,
                function(style) return style == nil or style == "default" or style == "compact" end,
                'must be "default" or "compact"',
            },
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
        })

        -- Additional validation for position if it exists
        if opts.position then
            vim.validate({
                ["position.row"] = { opts.position.row, "number" },
                ["position.col_offset"] = { opts.position.col_offset, "number" },
            })
        end

        -- Check min_width and max_width relationship if both are provided
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
