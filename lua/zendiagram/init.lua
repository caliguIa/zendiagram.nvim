local Zendiagram = {}

local api = vim.api
local diag_api = vim.diagnostic
local initialised = false
local ns_id = api.nvim_create_namespace("custom_diagnostic_highlight")

local BASE_PRIORITY = 9998
local HIGHLIGHT_PRIORITY = 9999

local opening_delimiters = "['\"<({%[`]"
local delimiters = {
    ["'"] = "'",
    ["`"] = "`",
    ['"'] = '"',
    ["<"] = ">",
    ["("] = ")",
    ["{"] = "}",
    ["["] = "]",
}

local apply_highlights = function(bufnr)
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

    for i, line in ipairs(lines) do
        -- Lua is 1 indexed but nvim API expects 0 indexed
        local row = i - 1

        -- Skip header and empty lines
        if row == 0 or #line == 0 then goto continue end

        -- Handle separator lines first
        if line:match("─") then
            api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {
                end_row = row,
                end_col = #line,
                hl_group = "NonText",
                priority = BASE_PRIORITY,
            })
            goto continue
        end

        -- Set the base highlight for the whole line
        api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {
            end_row = row,
            end_col = #line,
            hl_group = "Normal",
            priority = BASE_PRIORITY,
        })

        -- Set highlights for keywords
        local pos = 1
        while pos <= #line do
            local opening_index = line:find(opening_delimiters, pos)
            if not opening_index then break end

            local opening_char = line:sub(opening_index, opening_index)
            local closing_char = delimiters[opening_char]

            local closing_index = line:find(closing_char, opening_index + 1, true)
            if closing_index and closing_index > opening_index + 1 then -- Ensure content exists between delimiters
                api.nvim_buf_set_extmark(bufnr, ns_id, row, opening_index - 1, {
                    end_row = row,
                    end_col = closing_index,
                    hl_group = "@variable",
                    priority = HIGHLIGHT_PRIORITY,
                })
            end

            pos = (closing_index and closing_index + 1) or (opening_index + 1)
        end

        ::continue::
    end
end

local default_open_float = diag_api.open_float
Zendiagram.open = function(opts, ...)
    local float_bufnr = default_open_float(opts, ...)

    if not float_bufnr or not api.nvim_buf_is_valid(float_bufnr) then return float_bufnr end
    if not initialised then
        vim.notify(
            "Zendiagram not initialised, please call the setup function. Falling back to default diagnostics float",
            vim.log.levels.ERROR
        )
        return float_bufnr
    end

    -- Filter the list to only include windows that are displaying the given buffer
    local buffer_windows = {}
    for _, win_id in ipairs(api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win_id) == float_bufnr then table.insert(buffer_windows, win_id) end
    end

    local float_win = buffer_windows[1]
    local float_win_config = api.nvim_win_get_config(float_win)

    if not api.nvim_win_is_valid(float_win) or float_win_config.relative == "" then return float_bufnr end

    apply_highlights(float_bufnr)

    return float_bufnr
end

local set_diagnostic_float_config = function()
    diag_api.config({
        float = {
            scope = "line",
            header = " Diagnostics ",
            prefix = "",
            suffix = "",
            severity_sort = true,
            source = false,
            format = function(diagnostic)
                local source = diagnostic.source or ""
                if source:sub(-1, -1) == "." then source = source:sub(1, -2) end
                source = source .. ": "
                local output = " " .. source .. diagnostic.message .. " "

                local diagnostics_table = diag_api.get(diagnostic.bufnr, { lnum = diagnostic.lnum })
                table.sort(diagnostics_table, function(a, b) return a.severity < b.severity end)
                local diagnostics = vim.iter(diagnostics_table)

                if #diagnostics_table > 1 then
                    local longest_msg_len = diagnostics:fold(#(source .. diagnostic.message), function(acc, next)
                        local next_message = source .. next.message
                        return acc >= #next_message and acc or #next_message
                    end)

                    local is_last = diagnostic.message == diagnostics:last().message
                    if not is_last then
                        local separator = "\n" .. string.rep("─", longest_msg_len + 2)
                        output = output .. separator
                    end
                end

                return output
            end,
        },
    })
end

Zendiagram.setup = function()
    initialised = true
    diag_api.open_float = Zendiagram.open
    set_diagnostic_float_config()
end

return Zendiagram
