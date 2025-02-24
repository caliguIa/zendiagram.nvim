local Highlights = {}

local _config = require("zendiagram.config")
local _api = vim.api

local function set_highlights(highlights)
    for group_name, hl_config in pairs(highlights) do
        if type(hl_config) == "string" then
            _api.nvim_set_hl(0, group_name, { link = hl_config })
        else
            _api.nvim_set_hl(0, group_name, hl_config)
        end
    end
end

function Highlights.setup()
    local highlights = _config.highlights
    set_highlights(highlights)

    _api.nvim_create_autocmd("ColorScheme", {
        group = _api.nvim_create_augroup("ZendiagramHighlights", { clear = true }),
        callback = function() set_highlights(highlights) end,
    })
end

return Highlights
