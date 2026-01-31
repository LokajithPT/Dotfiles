local M = {}

local timer = nil
local heartbeat_interval = 10000 -- 10 seconds in milliseconds

-- Keystroke tracking
local keystroke_count = 0
local last_heartbeat_time = 0

-- Track keystrokes
local function track_keystroke()
    keystroke_count = keystroke_count + 1
    vim.g.duo_keystrokes_current = keystroke_count
end

-- Auto-setup keystroke tracking
vim.api.nvim_create_autocmd({"InsertEnter", "CmdlineEnter"}, {
    callback = function()
        vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI", "TextChangedP"}, {
            buffer = vim.api.nvim_get_current_buf(),
            callback = track_keystroke,
        })
    end,
})

local function send_keystrokes()
    if keystroke_count > 0 then
        local cmd = {
            'curl', '-s', '-X', 'POST',
            '-H', 'Content-Type: application/json',
            '-d', vim.fn.json_encode({keystrokes = keystroke_count}),
            'http://localhost:8080/api/keystrokes'
        }
        
        vim.fn.jobstart(cmd, {
            on_exit = vim.schedule_wrap(function(job_id, code, event)
                if code == 0 then
                    keystroke_count = 0
                    vim.g.duo_keystrokes_sent = (vim.g.duo_keystrokes_sent or 0) + keystroke_count
                else
                    vim.notify("Failed to send keystrokes to server", vim.log.levels.WARN, {title = "Duo"})
                end
            end)
        })
    end
end

-- Temporary placeholder - will be defined after profile_window_state


local function send_heartbeat()
    local current_time = os.time()
    
    -- Send keystrokes every 30 seconds
    if current_time - last_heartbeat_time >= 30 then
        send_keystrokes()
        last_heartbeat_time = current_time
    end
    
    -- Fetch dashboard data
    -- Fetch dashboard data
    M.fetch_dashboard_data()
    
    -- Also check simple heartbeat
    local cmd = {'wget', '-qO-', 'http://localhost:8080/heartbeat'}
    local job_stdout_buffer = {}

    vim.fn.jobstart(cmd, {
        on_stdout = vim.schedule_wrap(function(err, data, event)
            if data then
                for _, line in ipairs(data) do
                    if line then
                        table.insert(job_stdout_buffer, line)
                    end
                end
            end
        end),
        on_exit = vim.schedule_wrap(function(job_id, code, event)
            local filtered_data = {}
            for _, line in ipairs(job_stdout_buffer) do
                if line and line ~= "" then
                    table.insert(filtered_data, line)
                end
            end

            if #filtered_data > 0 then
                local raw_json_response = table.concat(filtered_data)
                local success, response_table = pcall(vim.fn.json_decode, raw_json_response)
                
                if success and response_table and response_table.status == "OK" then
                    vim.g.duo_server_status = "ACTIVE"
                else
                    vim.g.duo_server_status = "WARNING"
                end
            else
                vim.g.duo_server_status = "INACTIVE"
            end

            if code ~= 0 then
                vim.g.duo_server_status = "INACTIVE"
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

function M.fetch_dashboard_data()
    local cmd = {'curl', '-s', 'http://localhost:8080/api/dashboard'}
    local job_stdout_buffer = {}

    vim.fn.jobstart(cmd, {
        on_stdout = vim.schedule_wrap(function(err, data, event)
            if data then
                for _, line in ipairs(data) do
                    if line and line ~= "" then
                        table.insert(job_stdout_buffer, line)
                    end
                end
            end
        end),
        on_exit = vim.schedule_wrap(function(job_id, code, event)
            if code == 0 and #job_stdout_buffer > 0 then
                local raw_json = table.concat(job_stdout_buffer)
                local success, data = pcall(vim.fn.json_decode, raw_json)
                
                if success and data then
                    -- Update global variables for use in profile window
                    vim.g.duo_current_streak = data.user.currentStreak or 0
                    vim.g.duo_keystrokes_today = data.user.keystrokesToday or 0
                    vim.g.duo_current_level = data.user.currentLevel or 1
                    vim.g.duo_freezes_left = data.user.freezesLeft or 0
                    vim.g.duo_streak_status = data.user.streakStatus or "pending"
                    vim.g.duo_projects = data.projects or {}
                    vim.g.duo_tasks = data.tasks or {}
                    vim.g.duo_activities = data.activities or {}
                    
                    vim.g.duo_server_status = "ACTIVE"
                    
                    -- Force profile window to refresh if open
                    if profile_window_state.win_id and vim.api.nvim_win_is_valid(profile_window_state.win_id) then
                        if profile_window_state.update_content_fn then
                            profile_window_state.update_content_fn()
                        end
                    end
                end
            else
                vim.g.duo_server_status = "ERROR"
            end
        end)
    })
end

    local function get_profile_tab_lines(tab_idx, win_width)
        local header_lines = {}
        
        -- Add top border with rounded corners
        table.insert(header_lines, "╔" .. string.rep("═", win_width - 2) .. "╗")
        
        -- Add empty line for spacing
        table.insert(header_lines, "║" .. string.rep(" ", win_width - 2) .. "║")
        
        local tab_header = ""
        local total_tab_width = win_width - 2

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

    local footer_line = "╚" .. string.rep("═", win_width - 2) .. "╝"

    return vim.list_extend(header_lines, formatted_content, {footer_line})
end

function M.show_profile_window()
    if profile_window_state.win_id and vim.api.nvim_win_is_valid(profile_window_state.win_id) then
        vim.api.nvim_win_close(profile_window_state.win_id, true)
        profile_window_state.win_id = nil
        profile_window_state.buf_id = nil
        return -- Close existing window if re-called
    end

    -- Generate dynamic content based on real data
    local function generate_dynamic_content()
        local current_streak = vim.g.duo_current_streak or 0
        local keystrokes_today = vim.g.duo_keystrokes_today or 0
        local current_level = vim.g.duo_current_level or 1
        local freezes_left = vim.g.duo_freezes_left or 0
        local streak_status = vim.g.duo_streak_status or "pending"
        local projects = vim.g.duo_projects or {}
        local tasks = vim.g.duo_tasks or {}
        
        profile_window_state.tabs_content = {
            -- Tab 1: Streak & Approval
            {
                "",
                "  ┌─────────────────────────────────────────────────────┐",
                "  │ 🔥 STREAK & APPROVAL STATUS                   │",
                "  ├─────────────────────────────────────────────────────┤",
                "  │                                             │",
                "  │  Current Streak:    " .. string.format("%-3d", current_streak) .. " days 🔥       │",
                "  │  Status:           " .. string.format("%-12s", string.upper(streak_status)) .. "      │",
                "  │  Freezes Left:     " .. string.format("%-3d", freezes_left) .. " 🧊          │",
                "  │                                             │",
                "  │  📊 TODAY'S STATS                          │",
                "  │  Keystrokes:       " .. string.format("%-8d", keystrokes_today) .. "       │",
                "  │  Level:            " .. string.format("%-3d", current_level) .. " ⭐          │",
                "  │                                             │",
                "  └─────────────────────────────────────────────────────┘",
                "",
            },
            -- Tab 2: Project & Tasks
            {
                "",
                "  ┌─────────────────────────────────────────────────────┐",
                "  │ 💼 PROJECTS & TASKS                         │",
                "  ├─────────────────────────────────────────────────────┤",
                "  │                                             │",
                "  │  Active Projects:  " .. string.format("%-2d", #projects) .. "              │",
                "  │  Total Tasks:     " .. string.format("%-2d", #tasks) .. "              │",
                "  │                                             │",
            },
            -- Tab 3: Today's Focus
            {
                "",
                "  ┌─────────────────────────────────────────────────────┐",
                "  │ 🎯 TODAY'S FOCUS                           │",
                "  ├─────────────────────────────────────────────────────┤",
                "  │                                             │",
                "  │  Keep coding! You're doing great! 💪          │",
                "  │                                             │",
                "  │  Progress: " .. string.format("%-6.1f", (keystrokes_today / 100) * 100) .. "%     │",
                "  │                                             │",
                "  └─────────────────────────────────────────────────────┘",
                "",
            },
        }
        
        -- Add project and task details
        for _, project in ipairs(projects) do
            table.insert(profile_window_state.tabs_content[2], "  │  • " .. string.format("%-36s", project.name) .. " │")
        end
        
        if #tasks > 0 then
            table.insert(profile_window_state.tabs_content[2], "  │                                             │")
            table.insert(profile_window_state.tabs_content[2], "  │  📋 TASKS:                                 │")
        end
        
        for _, task in ipairs(tasks) do
            local status = task.completed and "✅" or "⭕"
            local desc = string.sub(task.description, 1, 36)
            if #task.description > 36 then desc = desc .. "..." end
            table.insert(profile_window_state.tabs_content[2], "  │  " .. status .. " " .. string.format("%-36s", desc) .. " │")
        end
        
        -- Add bottom border for Tab 2
        table.insert(profile_window_state.tabs_content[2], "  │                                             │")
        table.insert(profile_window_state.tabs_content[2], "  └─────────────────────────────────────────────────────┘")
        
        -- Add project details
        for _, project in ipairs(projects) do
            table.insert(profile_window_state.tabs_content[2], "  • " .. project.name)
        end
        
        -- Add task details
        table.insert(profile_window_state.tabs_content[2], "  Active Tasks:")
        for _, task in ipairs(tasks) do
            local status = task.completed and "[✓]" or "[ ]"
            table.insert(profile_window_state.tabs_content[2], "    " .. status .. " " .. task.description)
        end
        
        -- Fill remaining space
        for i = #profile_window_state.tabs_content[2], 10 do
            table.insert(profile_window_state.tabs_content[2], "")
        end
    end
    
    -- Call generate_dynamic_content every time profile window opens to get fresh data
    local function refresh_profile_content()
        if profile_window_state.win_id and vim.api.nvim_win_is_valid(profile_window_state.win_id) then
            generate_dynamic_content()
            if profile_window_state.update_content_fn then
                profile_window_state.update_content_fn()
            end
        end
    end
    
    generate_dynamic_content()
    
    -- Auto-refresh profile window content every 10 seconds
    local refresh_timer = vim.loop.new_timer()
    refresh_timer:start(10000, 10000, vim.schedule_wrap(refresh_profile_content))

    local win_width = 90 -- Much bigger width for better readability
    local win_height = 15 -- Taller height for more content

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
        border = "rounded", -- Sexy rounded border
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

    -- Set highlighting for the floating window with sexy colors
    vim.api.nvim_win_set_option(profile_window_state.win_id, "winhighlight", "Normal:NormalFloat,FloatBorder:FloatBorder")
    
    -- Define sexy highlight groups
    vim.api.nvim_set_hl(0, "DuoNormal", {bg = "#1e1e2e", fg = "#ffffff"})
    vim.api.nvim_set_hl(0, "DuoFloat", {bg = "#282c34", fg = "#abb2bf"})
    vim.api.nvim_set_hl(0, "DuoBorder", {fg = "#667eea", bg = "#1e1e2e"})
    vim.api.nvim_set_hl(0, "DuoTabActive", {fg = "#ffffff", bg = "#667eea", bold = true})
    vim.api.nvim_set_hl(0, "DuoTabInactive", {fg = "#abb2bf", bg = "#2a2b3a"})
    vim.api.nvim_set_hl(0, "DuoStreak", {fg = "#20c997", bold = true})
    vim.api.nvim_set_hl(0, "DuoLevel", {fg = "#f39c12", bold = true})
    vim.api.nvim_set_hl(0, "DuoKeystrokes", {fg = "#4ecdc4", bold = true})
    
    -- Apply highlights to buffer
    vim.api.nvim_win_set_option(profile_window_state.win_id, "winhighlight", "Normal:DuoNormal,FloatBorder:DuoBorder")

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
