---@class Zendiagram
local Zendiagram = {}

local _initialized = false
local _modules = {
    config = nil,
    float = nil,
    utils = nil,
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

    _modules.config.setup(opts)

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
