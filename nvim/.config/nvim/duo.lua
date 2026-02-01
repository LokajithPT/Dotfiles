local M = {}

local timer = nil
local heartbeat_interval = 10000 -- 10 seconds in milliseconds

local function send_heartbeat()
    local cmd = {'wget', '-qO-', 'http://localhost:8080/heartbeat'}
    local job_stdout_buffer = {} -- Buffer to collect stdout

    vim.fn.jobstart(cmd, {
        on_stdout = vim.schedule_wrap(function(err, data, event)
            if data then
                for _, line in ipairs(data) do
                    if line then -- Include empty lines here, filter later
                        table.insert(job_stdout_buffer, line)
                    end
                end
            end
        end),
        on_stderr = vim.schedule_wrap(function(err, data, event)
            local filtered_stderr_data = {}
            if data then
                for _, line in ipairs(data) do
                    if line and line ~= "" then
                        table.insert(filtered_stderr_data, line)
                    end
                end
            end

            if #filtered_stderr_data > 0 then
                vim.notify("Heartbeat failed (stderr): " .. table.concat(filtered_stderr_data), vim.log.levels.ERROR, {title = "Duo Heartbeat"})
                vim.g.duo_server_status = "ERROR"
            end
        end),
        on_exit = vim.schedule_wrap(function(job_id, code, event)
            local filtered_data = {}
            for _, line in ipairs(job_stdout_buffer) do
                if line and line ~= "" then -- Now filter empty lines from the collected buffer
                    table.insert(filtered_data, line)
                end
            end

            if #filtered_data > 0 then
                local raw_json_response = table.concat(filtered_data)
                local ok_to_ping = false
                local success, response_table = pcall(vim.fn.json_decode, raw_json_response)
                
                if success and response_table and response_table.status == "OK" then
                    ok_to_ping = true
                end

                if ok_to_ping then
                    vim.notify("Server pinged!", vim.log.levels.INFO, {title = "Duo Heartbeat"})
                    vim.g.duo_server_status = "ACTIVE"
                else
                    vim.notify("Heartbeat failed: Server response was not OK or invalid JSON. Response: " .. raw_json_response, vim.log.levels.ERROR, {title = "Duo Heartbeat"})
                    vim.g.duo_server_status = "WARNING"
                end
            else
                vim.notify("Heartbeat failed: Server did not respond or empty response (after filtering).", vim.log.levels.ERROR, {title = "Duo Heartbeat"})
                vim.g.duo_server_status = "INACTIVE"
            end

            if code ~= 0 then
                if not (#filtered_data > 0 and ok_to_ping) then 
                    vim.notify("Heartbeat failed: Command exited with code " .. code .. ".", vim.log.levels.ERROR, {title = "Duo Heartbeat"})
                    vim.g.duo_server_status = "INACTIVE"
                end
            end
        end)
    })
end

function M.start_heartbeat()
    if timer then
        timer:stop()
        timer = nil
    end

    timer = vim.loop.new_timer()
    timer:start(0, heartbeat_interval, vim.schedule_wrap(send_heartbeat))
    vim.notify("Duo Heartbeat started. Checking every " .. (heartbeat_interval / 1000) .. " seconds.", vim.log.levels.INFO, {title = "Duo Heartbeat"})
end

function M.show_profile_window()
    local profile_data = {
        streak_and_approval = {
            "  ╭───────────────────────────────────────────╮",
            "  │                                           │",
            "  │              DUO PROFILE                  │",
            "  │              (Streak & Approval)          │",
            "  ├───────────────────────────────────────────┤",
            "  │                                           │",
            "  │  Streak:           7 Days                 │",
            "  │  Streak Freezes:   3 Left                 │",
            "  │                                           │",
            "  ╰───────────────────────────────────────────╯",
        },
        project_and_tasks = {
            "  ╭───────────────────────────────────────────╮",
            "  │                                           │",
            "  │              DUO PROFILE                  │",
            "  │              (Project & Tasks)            │",
            "  ├───────────────────────────────────────────┤",
            "  │                                           │",
            "  │  Project:          Duolevelling CLI       │",
            "  │  Tasks:            [ ] Implement A Feature",
            "  │                     [ ] Fix Bug X         │",
            "  │                                           │",
            "  ╰───────────────────────────────────────────╯",
        },
        todays_task = {
            "  ╭───────────────────────────────────────────╮",
            "  │                                           │",
            "  │              DUO PROFILE                  │",
            "  │              (Today's Task)               │",
            "  ├───────────────────────────────────────────┤",
            "  │                                           │",
            "  │  Today's Task:     Implement Floating Window",
            "  │                                           │",
            "  ╰───────────────────────────────────────────╯",
        },
    }

    local current_tab = 1 -- Default to the first tab

    local tab_names = {"Streak & Approval", "Project & Tasks", "Today's Task"}
    local tabs_content = {
        profile_data.streak_and_approval,
        profile_data.project_and_tasks,
        profile_data.todays_task,
    }

    local function get_tab_lines(tab_idx)
        local header_line = "  "
        for i, name in ipairs(tab_names) do
            local padding = string.rep(" ", math.max(0, (win_width - 4 - #name) / 2)) -- approximate padding
            if i == tab_idx then
                header_line = header_line .. "│" .. padding .. name .. padding .. "│"
            else
                header_line = header_line .. "│" .. padding .. name .. padding .. "│"
            end
        end
        return vim.list_extend({"┌" .. string.rep("─", win_width - 2) .. "┐", header_line, "├" .. string.rep("─", win_width - 2) .. "┤"}, tabs_content[tab_idx])
    end


    local buf = vim.api.nvim_create_buf(false, {
        bufhidden = "wipe",
        buftype = "nofile",
        swapfile = false,
        ft = "duoprofile",
    })

    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)
    local win_width = 70 -- Fixed width for aesthetic and tab headers
    local win_height = 15 -- Adjust based on content

    local row = math.floor((height - win_height) / 2)
    local col = math.floor((width - win_width) / 2)

    local opts = {
        relative = "editor",
        row = row,
        col = col,
        width = win_width,
        height = win_height,
        border = "single", -- Using single for now, can be changed later
        style = "minimal",
        focusable = true,
    }

    local win = vim.api.nvim_open_win(buf, true, opts)

    local function update_window_content()
        vim.api.nvim_buf_set_lines(buf, 0, -1, true, get_tab_lines(current_tab))
        vim.api.nvim_win_set_cursor(win, {2, 2}) -- Move cursor off the border
    end

    update_window_content()

    -- Set highlighting for the floating window border
    vim.api.nvim_win_set_option(win, "winhighlight", "Normal:NormalFloat,FloatBorder:FloatBorder")

    -- Keybindings for tab switching (within the floating window)
    vim.api.nvim_buf_set_keymap(buf, "n", "<Tab>", [[<Cmd>lua require('duo').next_tab_profile_window()<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<S-Tab>", [[<Cmd>lua require('duo').prev_tab_profile_window()<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", [[<Cmd>close<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(buf, "n", "q", [[<Cmd>close<CR>]], {noremap = true, silent = true})
end

-- Global variables to manage the floating window state across calls
local profile_window_state = {
    win_id = nil,
    buf_id = nil,
    current_tab = 1,
    tab_names = {"Streak & Approval", "Project & Tasks", "Today's Task"},
    tabs_content = nil, -- Will be set dynamically
}

local function get_profile_tab_lines(tab_idx, win_width)
    local header_lines = {
        "┌" .. string.rep("─", win_width - 2) .. "┐",
    }
    local tab_header = ""
    local total_tab_width = win_width - 2 -- width for tab names excluding outer borders

    local tab_widths = {}
    local remaining_width = total_tab_width - ( #profile_window_state.tab_names * 2 ) -- account for 2 chars for separators

    -- Calculate widths based on content
    for i, name in ipairs(profile_window_state.tab_names) do
        tab_widths[i] = math.floor(remaining_width / #profile_window_state.tab_names)
    end
    -- Distribute remaining width due to floor division
    for i = 1, remaining_width % #profile_window_state.tab_names do
        tab_widths[i] = tab_widths[i] + 1
    end

    for i, name in ipairs(profile_window_state.tab_names) do
        local padding_left = math.floor((tab_widths[i] - #name) / 2)
        local padding_right = tab_widths[i] - #name - padding_left
        local tab_text = string.rep(" ", padding_left) .. name .. string.rep(" ", padding_right)

        if i == tab_idx then
            tab_header = tab_header .. "│" .. tab_text .. "│"
        else
            tab_header = tab_header .. "│" .. tab_text .. "│"
        end
    end
    tab_header = tab_header .. "│" -- Closing border
    table.insert(header_lines, tab_header)
    table.insert(header_lines, "├" .. string.rep("─", win_width - 2) .. "┤")

    local content = profile_window_state.tabs_content[tab_idx]
    
    -- Ensure content lines fit within win_width
    local formatted_content = {}
    local content_width = win_width - 4 -- 2 for outer border, 2 for inner padding
    for _, line in ipairs(content) do
        local trimmed_line = line:sub(1, content_width)
        table.insert(formatted_content, "│ " .. trimmed_line .. string.rep(" ", math.max(0, content_width - #trimmed_line)) .. " │")
    end

    local footer_line = "╰" .. string.rep("─", win_width - 2) .. "╯"

    return vim.list_extend(vim.list_extend(header_lines, formatted_content), {footer_line})
end

function M.show_profile_window()
    if profile_window_state.win_id and vim.api.nvim_win_is_valid(profile_window_state.win_id) then
        vim.api.nvim_win_close(profile_window_state.win_id, true)
        profile_window_state.win_id = nil
        profile_window_state.buf_id = nil
        return -- Close existing window if re-called
    end

    profile_window_state.tabs_content = {
        -- Tab 1: Streak & Approval
        {
            "  Streak:           7 Days",
            "  Streak Freezes:   3 Left",
            "",
            "",
            "",
            "",
            "",
        },
        -- Tab 2: Project & Tasks
        {
            "  Project:          Duolevelling CLI",
            "  Tasks:",
            "    [ ] Implement A Feature",
            "    [ ] Fix Bug X",
            "",
            "",
            "",
        },
        -- Tab 3: Today's Task
        {
            "  Today's Task:     Implement Floating Window",
            "",
            "",
            "",
            "",
            "",
            "",
        },
    }

    local win_width = 70 -- Fixed width for aesthetic and tab headers
    local win_height = 10 -- Height for content rows + 3 for header/footer

    profile_window_state.buf_id = vim.api.nvim_create_buf(false, {
        bufhidden = "wipe",
        buftype = "nofile",
        swapfile = false,
        ft = "duoprofile",
    })

    local width = vim.api.nvim_win_get_width(0)
    local height = vim.api.nvim_win_get_height(0)
    local row = math.floor((height - win_height) / 2) - 2 -- Adjust to account for tab header
    local col = math.floor((width - win_width) / 2)

    local opts = {
        relative = "editor",
        row = row,
        col = col,
        width = win_width,
        height = win_height,
        border = "none", -- Border handled by content
        style = "minimal",
        focusable = true,
        noautocmd = true,
    }

    profile_window_state.win_id = vim.api.nvim_open_win(profile_window_state.buf_id, true, opts)

    local function update_window_content()
        if vim.api.nvim_buf_is_valid(profile_window_state.buf_id) then
            vim.api.nvim_buf_set_lines(profile_window_state.buf_id, 0, -1, true, get_profile_tab_lines(profile_window_state.current_tab, win_width))
            vim.api.nvim_win_set_cursor(profile_window_state.win_id, {4, 2}) -- Move cursor off the border
        end
    end

    update_window_content()

    -- Set highlighting for the floating window border
    -- vim.api.nvim_win_set_option(profile_window_state.win_id, "winhighlight", "Normal:NormalFloat,FloatBorder:FloatBorder")
    vim.api.nvim_set_hl(0, "NormalFloat", {bg = "#282c34"}) -- Background for window content
    vim.api.nvim_set_hl(0, "FloatBorder", {fg = "#5a68a5", bg = "#282c34"}) -- Border color

    -- Keybindings for tab switching (within the floating window)
    vim.api.nvim_buf_set_keymap(profile_window_state.buf_id, "n", "<Tab>", [[<Cmd>lua require('duo').next_profile_tab()<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(profile_window_state.buf_id, "n", "<S-Tab>", [[<Cmd>lua require('duo').prev_profile_tab()<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(profile_window_state.buf_id, "n", "<Esc>", [[<Cmd>close<CR>]], {noremap = true, silent = true})
    vim.api.nvim_buf_set_keymap(profile_window_state.buf_id, "n", "q", [[<Cmd>close<CR>]], {noremap = true, silent = true})

    profile_window_state.update_content_fn = update_window_content -- Store update function
end

function M.next_profile_tab()
    if profile_window_state.win_id and vim.api.nvim_win_is_valid(profile_window_state.win_id) then
        profile_window_state.current_tab = profile_window_state.current_tab + 1
        if profile_window_state.current_tab > #profile_window_state.tab_names then
            profile_window_state.current_tab = 1
        end
        profile_window_state.update_content_fn()
    end
end

function M.prev_profile_tab()
    if profile_window_state.win_id and vim.api.nvim_win_is_valid(profile_window_state.win_id) then
        profile_window_state.current_tab = profile_window_state.current_tab - 1
        if profile_window_state.current_tab < 1 then
            profile_window_state.current_tab = #profile_window_state.tab_names
        end
        profile_window_state.update_content_fn()
    end
end

return M
