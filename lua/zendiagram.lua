local M = {}

-- Cache vim APIs for performance
local api = vim.api
local vdiagnostic = vim.diagnostic
local fn = vim.fn

-- Module state
local state = {
	config = {},
	last_line = nil,
	last_diagnostics = nil,
	debounce_timer = nil,
	ns_id = api.nvim_create_namespace("cursor_line_diagnostics"),
}

-- Events that trigger updates (now hardcoded)
local update_events = {
	"CursorMoved",
	"DiagnosticChanged",
	"TextChanged",
	"TextChangedI",
	"InsertChange",
}

-- Default configuration
local defaults = {
	prefix = "󰧞 ",
	clear_on_insert = true,
	display_mode = "overlay", -- "shift", "overlay", or "single"
	max_diagnostics = 3,
	debounce_ms = 50,
}

-- Utility Functions
local function validate_config(opts)
	assert(type(opts.max_diagnostics) == "number", "max_diagnostics must be a number")
	assert(
		opts.display_mode == "shift" or opts.display_mode == "overlay" or opts.display_mode == "single",
		"display_mode must be 'shift', 'overlay', or 'single'"
	)
	assert(type(opts.debounce_ms) == "number", "debounce_ms must be a number")
end

local function clear_virtual_text()
	api.nvim_buf_clear_namespace(0, state.ns_id, 0, -1)
end

local function diagnostic_key(diagnostic, line)
	return string.format("%d:%s:%s", line, diagnostic.message, diagnostic.severity or "")
end

local function get_cursor_info()
	local cursor_line = api.nvim_win_get_cursor(0)[1] - 1
	local win = api.nvim_get_current_win()
	local win_height = api.nvim_win_get_height(win)
	local win_top = fn.line("w0") - 1

	return {
		line = cursor_line,
		win_height = win_height,
		relative_pos = cursor_line - win_top,
		text = api.nvim_get_current_line(),
	}
end

local function has_diagnostics_changed(cursor_line, diagnostics)
	if state.last_line ~= cursor_line then
		return true
	end
	if #(state.last_diagnostics or {}) ~= #diagnostics then
		return true
	end
	return false
end

-- Display Functions
local function create_diagnostic_text(diagnostic_item)
	return {
		{
			state.config.prefix .. diagnostic_item.message,
			"DiagnosticVirtualText" .. vim.diagnostic.severity[diagnostic_item.severity],
		},
	}
end

local function display_single_mode(diagnostics, cursor_info)
	if #diagnostics == 0 then
		return
	end

	local displayed_diagnostics = {}
	local combined_virt_text = {}

	for _, d in ipairs(diagnostics) do
		local key = diagnostic_key(d, cursor_info.line)
		if not displayed_diagnostics[key] then
			-- Add separator between diagnostics
			if #combined_virt_text > 0 then
				table.insert(combined_virt_text, { " ", "Comment" })
			end

			-- Add diagnostic text
			table.insert(combined_virt_text, {
				state.config.prefix .. d.message,
				"DiagnosticVirtualText" .. vim.diagnostic.severity[d.severity],
			})
			displayed_diagnostics[key] = true
		end
	end

	if #combined_virt_text > 0 then
		api.nvim_buf_set_extmark(0, state.ns_id, cursor_info.line, 0, {
			virt_text = combined_virt_text,
			virt_text_pos = "eol",
		})
	end
end

local function display_shift_mode(diagnostics, cursor_info)
	if #diagnostics == 0 then
		return
	end

	local displayed_diagnostics = {}
	local first_diagnostic = diagnostics[1]
	local first_key = diagnostic_key(first_diagnostic, cursor_info.line)
	local padding = string.rep(" ", fn.strdisplaywidth(cursor_info.text) + 1)

	if not displayed_diagnostics[first_key] then
		-- Create first diagnostic line
		local first_virt_text = create_diagnostic_text(first_diagnostic)
		displayed_diagnostics[first_key] = true

		-- Create subsequent diagnostic lines
		local virt_lines = {}
		for i = 2, #diagnostics do
			local d = diagnostics[i]
			local key = diagnostic_key(d, cursor_info.line)
			if not displayed_diagnostics[key] then
				table.insert(virt_lines, {
					{ padding, "" },
					{
						state.config.prefix .. d.message,
						"DiagnosticVirtualText" .. vim.diagnostic.severity[d.severity],
					},
				})
				displayed_diagnostics[key] = true
			end
		end

		-- Set extmark with all diagnostic information
		api.nvim_buf_set_extmark(0, state.ns_id, cursor_info.line, 0, {
			virt_text = first_virt_text,
			virt_text_pos = "eol",
			virt_lines = #virt_lines > 0 and virt_lines or nil,
		})
	end
end

local function display_overlay_mode(diagnostics, cursor_info)
	if #diagnostics == 0 then
		return
	end

	local needed_lines = #diagnostics
	local lines_below = cursor_info.win_height - cursor_info.relative_pos

	-- Only show diagnostics if we have space
	if needed_lines > lines_below then
		return
	end

	local eol_col = fn.strdisplaywidth(cursor_info.text) + 1
	local displayed_diagnostics = {}

	-- Place first diagnostic
	local first_key = diagnostic_key(diagnostics[1], cursor_info.line)
	if not displayed_diagnostics[first_key] then
		api.nvim_buf_set_extmark(0, state.ns_id, cursor_info.line, 0, {
			virt_text = create_diagnostic_text(diagnostics[1]),
			virt_text_pos = "overlay",
			virt_text_win_col = eol_col,
			priority = 100,
		})
		displayed_diagnostics[first_key] = true

		-- Place subsequent diagnostics
		local line_offset = 1
		for i = 2, #diagnostics do
			local d = diagnostics[i]
			local key = diagnostic_key(d, cursor_info.line)
			if not displayed_diagnostics[key] then
				api.nvim_buf_set_extmark(0, state.ns_id, cursor_info.line + line_offset, 0, {
					virt_text = create_diagnostic_text(d),
					virt_text_pos = "overlay",
					virt_text_win_col = eol_col,
					priority = 100 + line_offset,
				})
				displayed_diagnostics[key] = true
				line_offset = line_offset + 1
			end
		end
	end
end

-- Main Functions
local function handle_diagnostics()
	if fn.mode():match("^i") then
		clear_virtual_text()
		return
	end

	local cursor_info = get_cursor_info()
	local diagnostics = vdiagnostic.get(0, { lnum = cursor_info.line })

	-- Limit number of diagnostics shown
	diagnostics = vim.list_slice(diagnostics, 1, state.config.max_diagnostics)

	-- Check if we need to update
	if not has_diagnostics_changed(cursor_info.line, diagnostics) then
		return
	end

	-- Update state
	state.last_line = cursor_info.line
	state.last_diagnostics = diagnostics

	-- Clear existing virtual text
	clear_virtual_text()

	-- Display diagnostics based on mode
	if state.config.display_mode == "shift" then
		display_shift_mode(diagnostics, cursor_info)
	elseif state.config.display_mode == "single" then
		display_single_mode(diagnostics, cursor_info)
	else
		display_overlay_mode(diagnostics, cursor_info)
	end
end

local function debounced_handle_diagnostics()
	if state.debounce_timer then
		state.debounce_timer:stop()
	end

	state.debounce_timer = vim.defer_fn(function()
		handle_diagnostics()
		state.debounce_timer = nil
	end, state.config.debounce_ms)
end

-- Setup Function
function M.setup(opts)
	-- Merge and validate config
	local user_opts = opts or {}
	state.config = vim.tbl_deep_extend("force", defaults, user_opts)
	validate_config(state.config)

	-- Disable default virtual text
	vdiagnostic.config({ virtual_text = false })

	-- Create augroup
	local group = api.nvim_create_augroup("ZenDiagram", { clear = true })

	-- Setup InsertEnter autocmd separately if needed
	if state.config.clear_on_insert then
		api.nvim_create_autocmd("InsertEnter", {
			group = group,
			callback = clear_virtual_text,
		})
	end

	-- Setup InsertLeave autocmd separately to ensure immediate update
	api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = function()
			-- Reset last line to force update
			state.last_line = nil
			-- Immediate update without debounce
			vim.schedule(handle_diagnostics)
		end,
	})

	-- Setup other events with debouncing
	api.nvim_create_autocmd(update_events, {
		group = group,
		callback = debounced_handle_diagnostics,
	})
end

-- Public API
function M.refresh()
	handle_diagnostics()
end

return M
