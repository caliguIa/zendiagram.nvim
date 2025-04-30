local Zendiagram = {}
local H = {}

Zendiagram.setup = function(config)
    H.initialised = true
    H.config = H.setup_config(config)
    _G.Zendiagram = Zendiagram
    H.set_diagnostic_float_config()
    H.create_default_hl()
    H.create_autocmds()
    H.create_user_cmds()
end

Zendiagram.open = function(opts, ...)
    if H.disable then return nil end

    local float_bufnr, float_winid = H.virgin_open_float(opts, ...)

    if not H.initialised then
        vim.notify(
            "Zendiagram not initialised, please call the setup function. Falling back to default diagnostics float",
            vim.log.levels.ERROR
        )
        return float_bufnr
    end

    if float_winid and vim.api.nvim_win_is_valid(float_winid) then
        H.float_cache.winid = float_winid
        H.float_cache.bufnr = vim.api.nvim_win_get_buf(H.float_cache.winid)
        H.apply_highlights(H.float_cache.bufnr)

        if H.config.relative ~= "line" then H.position_float() end
    end

    return H.float_cache.bufnr, H.float_cache.winid
end

H.apply_highlights = function(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
        local row = i - 1
        if #line == 0 then goto continue end

        if row == 0 then
            vim.api.nvim_buf_set_extmark(bufnr, H.ns_id, row, 0, {
                end_row = row,
                end_col = #line,
                hl_group = H.hl_groups.header,
                priority = H.highlight_base_priority,
            })
        end

        -- Set highlight for separator line
        if line:match(H.separator_char) then
            vim.api.nvim_buf_set_extmark(bufnr, H.ns_id, row, 0, {
                end_row = row,
                end_col = #line,
                hl_group = H.hl_groups.separator,
                priority = H.highlight_base_priority,
            })
            goto continue
        end

        -- Set the base highlight for the whole line
        vim.api.nvim_buf_set_extmark(bufnr, H.ns_id, row, 0, {
            end_row = row,
            end_col = #line,
            hl_group = H.hl_groups.text,
            priority = H.highlight_base_priority,
        })

        -- Set highlights for keywords
        local pos = 1
        while pos <= #line do
            local opening_index = line:find(H.opening_delimiters, pos)
            if not opening_index then break end

            local opening_char = line:sub(opening_index, opening_index)
            local closing_char = H.delimiters[opening_char]

            local closing_index = line:find(closing_char, opening_index + 1, true)
            if closing_index and closing_index > opening_index + 1 then -- Ensure content exists between delimiters
                vim.api.nvim_buf_set_extmark(bufnr, H.ns_id, row, opening_index - 1, {
                    end_row = row,
                    end_col = closing_index,
                    hl_group = H.hl_groups.keyword,
                    priority = H.highlight_acc_priority,
                })
            end

            pos = (closing_index and closing_index + 1) or (opening_index + 1)
        end

        ::continue::
    end
end

function H.get_separator(length)
    if not H.separator_cache[length] then H.separator_cache[length] = "\n" .. string.rep(H.separator_char, length) end
    return H.separator_cache[length]
end

H.format_diagnostic = function(diagnostic)
    local cache_key = diagnostic.bufnr .. "_" .. diagnostic.lnum .. "_" .. diagnostic.col .. "_" .. diagnostic.severity
    if H.format_cache[cache_key] then return H.format_cache[cache_key] end

    local source = H.config.source and diagnostic.source or "" or ""
    if #source > 0 then
        if source:sub(-1, -1) == "." then source = source:sub(1, -2) end
        source = source .. ": "
    end
    local output = " " .. source .. diagnostic.message .. " "

    local all_diagnostics = vim.diagnostic.get(diagnostic.bufnr, { lnum = diagnostic.lnum })
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
            local separator = H.get_separator(longest_msg_len + 2)
            output = output .. separator
        end
    end

    H.format_cache[cache_key] = output
    return output
end

H.set_diagnostic_float_config = function()
    vim.diagnostic.config({
        float = {
            header = " " .. H.config.header .. " ",
            prefix = "",
            suffix = "",
            severity_sort = true,
            source = false,
            format = H.format_diagnostic,
        },
    })
end

H.position_float = function()
    local float_width = vim.api.nvim_win_get_width(0)
    local float_height = vim.api.nvim_win_get_height(0)
    local config = vim.api.nvim_win_get_config(H.float_cache.winid)
    local coords = {
        NE = { row = 0, col = float_width - 1 },
        SE = { row = float_height - 1, col = float_width - 1 },
        SW = { row = float_height - 1, col = 1 },
        NW = { row = 0, col = 1 },
    }
    config = vim.tbl_extend("force", config, {
        relative = H.config.relative,
        anchor = H.config.anchor,
        row = coords[H.config.anchor].row,
        col = coords[H.config.anchor].col,
    })
    vim.api.nvim_win_set_config(H.float_cache.winid, config)
end

H.validate = function(name, value, type, optional) vim.validate(name, value, type, optional or false, type) end

H.setup_config = function(config)
    H.validate("config", config, "table", true)
    config = vim.tbl_deep_extend("force", vim.deepcopy(H.default_config), config or {})

    H.validate("header", config.header, "string")
    H.validate("source", config.source, "boolean")
    H.validate("relative", config.relative, "string")
    H.validate("anchor", config.anchor or "", "string", true)

    return config
end

H.create_default_hl = function()
    local set_default_hl = function(name, data)
        data.default = true
        vim.api.nvim_set_hl(0, name, data)
    end

    set_default_hl("ZendiagramText", { link = "Normal" })
    set_default_hl("ZendiagramKeyword", { link = "@variable" })
    set_default_hl("ZendiagramSeparator", { link = "NonText" })
    set_default_hl("ZendiagramHeader", { link = "FloatTitle" })
end

H.create_autocmds = function()
    local group = vim.api.nvim_create_augroup("Zendiagram", { clear = false })

    vim.api.nvim_create_autocmd({ "BufDelete" }, {
        group = group,
        callback = function()
            H.float_cache = { float_winid = nil, float_bufnr = nil }
            H.format_cache = {}
            H.separator_cache = {}
        end,
        desc = "Clear cache",
    })

    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        group = group,
        callback = function()
            H.disable = true
            if H.float_cache.float_winid and vim.api.nvim_win_is_valid(H.float_cache.float_winid) then
                vim.api.nvim_win_close(H.float_cache.float_winid, true)
                return true
            end
        end,
        desc = "Close diagnostics float & disable",
    })
    vim.api.nvim_create_autocmd({ "InsertLeave" }, {
        group = group,
        callback = function() H.disable = false end,
        desc = "Re-enable diagnostics float",
    })

    vim.api.nvim_create_autocmd({ "ColorScheme" }, {
        group = group,
        callback = function() H.create_default_hl() end,
        desc = "Ensure colours",
    })
end

H.create_user_cmds = function()
    vim.api.nvim_create_user_command("Zendiagram", function(opts)
        if opts.args == "open" then
            Zendiagram.open()
        else
            vim.notify("Unknown Zendiagram command: " .. opts.args, vim.log.levels.ERROR)
        end
    end, {
        nargs = 1,
        complete = function(_, _, _) return { "open" } end,
        desc = "Commands for Zendiagram plugin",
    })
end

H.default_config = {
    header = "Diagnostics",
    source = true,
    relative = "line",
    anchor = "NE",
}

H.virgin_open_float = vim.diagnostic.open_float
H.ns_id = vim.api.nvim_create_namespace("custom_diagnostic_highlight")

H.highlight_base_priority = 9998
H.highlight_acc_priority = 9999
--stylua: ignore
H.hl_groups = {
    text = "ZendiagramText", keyword = "ZendiagramKeyword",
    separator = "ZendiagramSeparator", header = "ZendiagramHeader",
}
H.separator_char = "─"
H.opening_delimiters = "['\"<({%[`]"
--stylua: ignore
H.delimiters = {
    ["'"] = "'", ["`"] = "`", ['"'] = '"', ["<"] = ">",
    ["("] = ")", ["{"] = "}", ["["] = "]",
}
H.float_cache = { winid = nil, bufnr = nil }
H.format_cache = {}
H.separator_cache = {}
H.initialised = false
H.disable = false

return Zendiagram
