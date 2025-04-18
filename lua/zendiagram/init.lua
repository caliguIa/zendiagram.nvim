---@class Zendiagram
local Zendiagram = {}

local _initialized = false
local _modules = {
    config = nil,
    float = nil,
    utils = nil,
    highlights = nil,
}

---@param opts table|nil Configuration options
---@return Zendiagram
function Zendiagram.setup(opts)
    if _initialized then
        vim.notify("Zendiagram is already initialized", vim.log.levels.WARN)
        return Zendiagram
    end

    _modules.config = require("zendiagram.config")
    _modules.float = require("zendiagram.float")
    _modules.utils = require("zendiagram.utils")
    _modules.highlights = require("zendiagram.highlights")

    _modules.config.setup(opts)
    _modules.highlights.setup()

    vim.api.nvim_create_user_command("Zendiagram", function(cmd_opts)
        local args = vim.split(cmd_opts.args, "%s+", { trimempty = true })
        local subcmd = args[1]

        if subcmd == "open" then
            Zendiagram.open(args[2] and { focus = args[2] } or {})
        elseif subcmd == "close" then
            Zendiagram.close()
        else
            vim.notify("Unknown Zendiagram command: " .. (subcmd or ""), vim.log.levels.ERROR)
        end
    end, {
        desc = "Zendiagram commands",
        nargs = "*",
        complete = function() return { "open", "close" } end,
    })

    _initialized = true
    return Zendiagram
end

---@param opts table|nil Options for opening the window
function Zendiagram.open(opts)
    if not _initialized then
        vim.notify("Zendiagram needs to be initialized first. Call setup()", vim.log.levels.ERROR)
        return
    end
    _modules.float.open(opts)
end

function Zendiagram.close()
    if not _initialized then return end
    _modules.float.close()
end

return Zendiagram
