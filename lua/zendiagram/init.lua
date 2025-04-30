local Zendiagram = {}

local api = vim.api
local dapi = vim.diagnostic

local highlight_base_priority = 9998
local highlight_acc_priority = 9999
local separator_char = "─"
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
local float_cache = { winid = nil, bufnr = nil }
local format_cache = {}
local separator_cache = {}
local initialised = false
local virgin_open_float = dapi.open_float
local ns_id = api.nvim_create_namespace("custom_diagnostic_highlight")

local apply_highlights = function(bufnr)
    local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
        local row = i - 1
        if row == 0 or #line == 0 then goto continue end

        -- Set highlight for separator line
        if line:match(separator_char) then
            api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {
                end_row = row,
                end_col = #line,
                hl_group = "NonText",
                priority = highlight_base_priority,
            })
            goto continue
        end

        -- Set the base highlight for the whole line
        api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, {
            end_row = row,
            end_col = #line,
            hl_group = "Normal",
            priority = highlight_base_priority,
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
                    priority = highlight_acc_priority,
                })
            end

            pos = (closing_index and closing_index + 1) or (opening_index + 1)
        end

        ::continue::
    end
end

local function get_separator(length)
    if not separator_cache[length] then separator_cache[length] = "\n" .. string.rep(separator_char, length) end
    return separator_cache[length]
end

local format_diagnostic = function(diagnostic)
    local cache_key = diagnostic.bufnr .. "_" .. diagnostic.lnum .. "_" .. diagnostic.col .. "_" .. diagnostic.severity
    if format_cache[cache_key] then return format_cache[cache_key] end

    local source = diagnostic.source or ""
    if source:sub(-1, -1) == "." then source = source:sub(1, -2) end
    source = source .. ": "
    local output = " " .. source .. diagnostic.message .. " "

    local all_diagnostics = dapi.get(diagnostic.bufnr, { lnum = diagnostic.lnum })
    if #all_diagnostics > 1 then
        table.sort(all_diagnostics, function(a, b) return a.severity < b.severity end)

        -- Calculate longest message once
        local longest_msg_len = 0
        for _, diag in ipairs(all_diagnostics) do
            local msg_len = #(source .. diag.message)
            if msg_len > longest_msg_len then longest_msg_len = msg_len end
        end

        -- Check if this is the last diagnostic
        local is_last = true
        for _, diag in ipairs(all_diagnostics) do
            if diag.severity > diagnostic.severity then
                is_last = false
                break
            end
        end

        if not is_last then
            local separator = get_separator(longest_msg_len + 2)
            output = output .. separator
        end
    end

    format_cache[cache_key] = output
    return output
end

local set_diagnostic_float_config = function()
    dapi.config({
        float = {
            scope = "line",
            header = " Diagnostics ",
            prefix = "",
            suffix = "",
            severity_sort = true,
            source = false,
            format = format_diagnostic,
        },
    })
end

local setup_autocmds = function()
    local group = api.nvim_create_augroup("Zendiagram", { clear = true })

    api.nvim_create_autocmd({ "BufDelete" }, {
        group = group,
        callback = function()
            float_cache = { float_winid = nil, float_bufnr = nil }
            format_cache = {}
            separator_cache = {}
        end,
    })
end

Zendiagram.open = function(opts, ...)
    local float_bufnr, float_winid = virgin_open_float(opts, ...)

    if not initialised then
        vim.notify(
            "Zendiagram not initialised, please call the setup function. Falling back to default diagnostics float",
            vim.log.levels.ERROR
        )
        return float_bufnr
    end

    if float_winid and api.nvim_win_is_valid(float_winid) then
        float_cache.winid = float_winid
        float_cache.bufnr = api.nvim_win_get_buf(float_cache.winid)
        apply_highlights(float_cache.bufnr)
    end

    return float_cache.bufnr, float_cache.winid
end

Zendiagram.setup = function()
    initialised = true
    dapi.open_float = Zendiagram.open
    set_diagnostic_float_config()
    setup_autocmds()
end

return Zendiagram
