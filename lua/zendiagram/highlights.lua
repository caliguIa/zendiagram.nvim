local Highlights = {}

local _config = require("zendiagram.config")
local _api = vim.api

function Highlights.setup()
    local highlights = _config.highlights

    for group_name, hl_config in pairs(highlights) do
        if type(hl_config) == "string" then
            _api.nvim_set_hl(0, group_name, { link = hl_config })
        else
            _api.nvim_set_hl(0, group_name, hl_config)
        end
    end
end

return Highlights
