-- ========================
-- Lazy.nvim Bootstrap
-- ========================

vim.g.mapleader = " "
vim.g.maplocalleader = " "


local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- =========================
-- General Settings
-- =========================
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.wo.relativenumber = true
vim.opt.clipboard = "unnamedplus"

-- =========================
-- Lazy-loaded Plugins
-- =========================
require("lazy").setup({

  -- ollama 
    

  {
  "nomnivore/ollama.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },

  config = function(_, opts) 
    require("ollama").setup({
      prompts = {
        AnalyzeFile = {
          prompt = "Analyze this file deeply:\n\n$file_content",
          model = "gemma3:4b",
        },
      },
    })
  end,

  keys = {
    -- Basic prompt window
    {
      "<leader>oo",
      ":<c-u>lua require('ollama').prompt()<cr>",
      desc = "ollama prompt",
      mode = { "n", "v" },
    },

    -- Code generation preset
    {
      "<leader>oa",
      function()
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local file_content = table.concat(lines, "\n")
        require("ollama").prompt({
          prompt = "AnalyzeFile",
          file_content = file_content,
        })
      end,
      desc = "ollama analyze file",
      mode = { "n", "v" },
    },

    -- Chat mode (side panel)
    {
      "<leader>oc",
      function() require("ollama").chat() end,
      desc = "ollama chat",
    },

    -- Analyze current buffer
    {
      "<leader>oa",
      function()
        local buf = vim.api.nvim_get_current_buf()
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local file = table.concat(lines, "\n")
        require("ollama").prompt({ prompt = "Analyze this file deeply:\n\n" .. file })
      end,
      desc = "ollama analyze file",
    },
  },

  opts = {
    model = "gemma3:4b",     -- your Ollama model
    debounce = 200,
    ui = {
      layout = "float",
      width = 0.7,
      height = 0.85,
    },
  }
},


    -- Auto Pairs

    -- Snacks.nvim (dependency for opencode) 
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },

    -- OpenCode integration
    { "windwp/nvim-autopairs", config = function() require("nvim-autopairs").setup{} end },

  
  {
    "David-Kunz/gen.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("gen").setup({
            model = "gemma3:4b",
            provider = "ollama",
            display_mode = "float",
            default_prompt = "You are a coding expert. Help me write, explain, or refactor code."
        })

        local function toggle_gen_chat()
            local bufnr = vim.fn.bufnr('gen-chat')
            if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
                vim.cmd('bdelete! ' .. bufnr)
            else
                vim.cmd('Gen Chat')
            end
        end

        --hotkey 
        vim.keymap.set("n", "<C-a>", toggle_gen_chat, {noremap=true, silent=true})
    end
},


    {
  "gisketch/triforce.nvim",
  dependencies = {
    "nvzone/volt",
  },
  config = function()
    require("triforce").setup({
      -- Optional: Add your configuration here
      keymap = {
        show_profile = "<leader>tp", -- Open profile with <leader>tp
      },
    })
  end,
}, 

    -- Emmet
    {
        "mattn/emmet-vim",
        config = function()
            vim.g.user_emmet_expandabbr_key = "<C-y>"
            vim.g.user_emmet_settings = { jsx = { self_closing_tag = true } }
        end,
    },    -- Mason (LSP installer)

    -- Completion Engine
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "L3MON4D3/LuaSnip",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                snippet = {
                    expand = function(args) 
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<C-j>"] = cmp.mapping.select_next_item(),
                    ["<C-k>"] = cmp.mapping.select_prev_item(),
                    ["<Tab>"] = cmp.mapping(function(fallback) 
                        if cmp.visible() then
                            cmp.select_next_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback) 
                        if cmp.visible() then
                            cmp.select_prev_item()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                }),
            })
        end,
    },


    { "ThePrimeagen/vim-be-good", cmd = "VimBeGood" },

    -- Auto close tags
    { "windwp/nvim-ts-autotag", dependencies = "nvim-treesitter/nvim-treesitter", config = function() 
        require("nvim-ts-autotag").setup()
    end },

    -- Neoscroll
    { "karb94/neoscroll.nvim", config = function() 
        require("neoscroll").setup({
            easing_function = "cubic",
            hide_cursor = true,
            stop_eof = true,
            respect_scrolloff = true,
            cursor_scrolls_alone = true,
        })
    end },

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function() 
            local telescope = require("telescope")
            telescope.setup{
                defaults = {
                    prompt_prefix = "> ",
                    color_devicons = true,
                    file_ignore_patterns = { ".git/", "node_modules/" },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                        find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
                    },
                },
            }
            telescope.load_extension("fzf")
        end,
    },
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

    -- Nvim Tree
    { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" }, config = function() 
        require("nvim-tree").setup { view = { width = 30, side = "left" }, filters = { dotfiles = false } }
    end },

    -- Git Signs
    { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup{} end },

    -- Copilot
    --{
    --    "zbirenbaum/copilot.lua",
    --     cmd = "Copilot",
     --   event = "InsertEnter",
       -- dependencies = { "nvim-lua/plenary.nvim" },
        --config = function()
          --  require("copilot").setup {
            --    suggestion = { enabled = true, auto_trigger = true,
              --      keymap = { next = "<C-j>", prev = "<C-k>", dismiss = "<C-] >",
                --    },
                --},
              --  panel = { enabled = false },
            --}
        --end,
    --}
    
    --avante 
{"MunifTanjim/nui.nvim"},
    
{
  "yetone/avante.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    require("avante").setup({
      provider = "ollama",
      url = "http://localhost:11434",  -- default ollama server
                model = "gemma3:4b",
      inline = {
        enabled = true, 
        debounce = 80, 
      }, 
      -- optional but recommended tweaks
      debounce_ms = 120,
      max_tokens = 4096,
      temperature = 0.2,
    })
  end,
},


    -- ToggleTerm
    { "akinsho/toggleterm.nvim", version = "*", config = function() 
        require("toggleterm").setup({
            open_mapping = [[<C-\]>]],
            direction = "float",
            shell = "fish",
            shade_terminals = false,
            start_in_insert = true
        })
        
        -- Map <C-l> to open a vertical terminal side pane
        vim.keymap.set({"n", "t"}, "<C-l>", "<Cmd>ToggleTerm size=60 direction=vertical<CR>", {noremap=true, silent=true})
        -- Keymaps for resizing the current window (primarily for the side terminal)
        vim.keymap.set({"n", "t"}, "<C-S-j>", "<Cmd>vertical resize -5<CR>", {noremap=true, silent=true})
        vim.keymap.set({"n", "t"}, "<C-S-k>", "<Cmd>vertical resize +5<CR>", {noremap=true, silent=true})

        -- Force <C-c> to be sent to the terminal shell
        vim.api.nvim_create_autocmd("TermOpen", {
            pattern = "term://*",
            callback = function() 
                vim.keymap.set("t", "<C-c>", "<C-c>", { buffer = true, noremap = true })
                -- Map <Esc> to exit terminal-mode (enables scrolling/visual mode)
                vim.keymap.set("t", "<Esc>", [[<C-\]><C-n>]], { buffer = true, noremap = true })
            end,
        })
    end },

    -- Hop
    { "phaazon/hop.nvim", branch = "v2", config = function() require("hop").setup{} end },

    -- Nightfox
    { "EdenEast/nightfox.nvim" },

    -- None-ls (modern replacement for null-ls)
{ "nvimtools/none-ls.nvim", dependencies = "nvim-lua/plenary.nvim", config = function() 
    local null_ls = require("null-ls")
    null_ls.setup({
        sources = {
            null_ls.builtins.formatting.prettier.with({
                filetypes = { "javascript","javascriptreact","typescript","typescriptreact","json","css","html" }
            }),
            null_ls.builtins.formatting.clang_format,
            null_ls.builtins.formatting.gofmt,
        },
        on_attach = function(client) 
            if client.supports_method("textDocument/formatting") then
                vim.cmd("autocmd BufWritePre <buffer> lua vim.lsp.buf.format()")
            end
        end
    })
end },

    -- Undotree
    {
        "mbbill/undotree",
        config = function()
            vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
        end,
    },

    -- DAP
    { "mfussenegger/nvim-dap" },

    -- Mason (LSP Installer)
{
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
    },
    config = function() 
        require("mason").setup({
            ensure_installed = { "codelldb" },
        })

        local on_attach = function(_, bufnr) 
            local opts = { buffer = bufnr, noremap = true, silent = true }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        end

        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        require("mason-lspconfig").setup({
            ensure_installed = { "clangd", "gopls", "pyright" },
            automatic_installation = true,
            handlers = {
                function(server_name) -- default handler
                    require("lspconfig")[server_name].setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                    })
                end,
                clangd = function() 
                    require("lspconfig").clangd.setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                        cmd = { "clangd", "--background-index", "--clang-tidy" },
                    })
                end,
                gopls = function() 
                    require("lspconfig").gopls.setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                        settings = {
                            gopls = {
                                analyses = { unusedparams = true },
                                staticcheck = true,
                            },
                        },
                    })
                end,
                 pyright = function()
                    require("lspconfig").pyright.setup({
                        on_attach = on_attach,
                        capabilities = capabilities,
                        settings = {
                            python = {
                                analysis = {
                                    autoSearchPaths = true,
                                    useLibraryCodeForTypes = true,
                                    diagnosticMode = "workspace"
                                }
                            }
                        }
                    })
                end,
            },
        })

        -- Setup bacon-ls manually since it's not in mason-lspconfig's default handlers
        require("lspconfig").bacon_ls.setup({
            on_attach = on_attach,
            capabilities = capabilities,
        })
    end,
},


    -- Harpoon
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = { "nvim-lua/plenary.nvim" },
        config = function() 
            local harpoon = require("harpoon")
            harpoon:setup()
            
            -- Keybindings
            vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, opts)
            vim.keymap.set("n", "<C-s>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, opts)
            vim.keymap.set("n", "<C-k>", function() harpoon:list():prev() end, opts)
            vim.keymap.set("n", "<C-j>", function() harpoon:list():next() end, opts)
        end,
    },

    -- Lualine
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function() 
            require("lualine").setup({
                options = {
                    theme = "auto",
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    globalstatus = true,
                },
                sections = {
                    lualine_a = { { "mode", fmt = function(str) return str:sub(1, 1) end } },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { { "filename", path = 1 }, 
                        function()
                            local ok, opencode = pcall(require, "opencode")
                            return ok and opencode.statusline() or ""
                        end
                    },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location" },
                },
            })
        end,
    },

    -- Alpha-nvim
    {
        "goolord/alpha-nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function() 
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")
            
            dashboard.section.header.val = {
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
                "    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
            }
            
            dashboard.section.buttons.val = {
                dashboard.button("f", "  Find file", ":Telescope find_files <CR>"),
                dashboard.button("n", "  New file", ":ene <BAR> startinsert <CR>"),
                dashboard.button("r", "  Recent", ":Telescope oldfiles <CR>"),
                dashboard.button("g", "  Find text", ":Telescope live_grep <CR>"),
                dashboard.button("c", "  Config", ":e ~/.config/nvim/init.lua <CR>"),
                dashboard.button("q", "  Quit", ":qa<CR>"),
            }
            
            dashboard.section.footer.val = "Welcome back, homie! 🚀"
            
            alpha.setup(dashboard.config)
        end,
    },

    -- Comment
    { "numToStr/Comment.nvim", config = function() require("Comment").setup() end },

    -- Treesitter
    { "nvim-treesitter/nvim-treesitter", build=":TSUpdate", config = function() 
        require("nvim-treesitter.configs").setup{
            highlight = { enable = true },
            ensure_installed = { "lua","python","c","cpp","javascript", "go" , "rust" },
            incremental_selection = {
                enable = true,
                keymaps = { init_selection="gnn", node_incremental="grn", scope_incremental="grc", node_decremental="grm" },
            },
        }
    end },
})

-- =========================
-- Key Mappings
-- =========================
local opts = { noremap=true, silent=true }

-- NvimTree toggle
vim.keymap.set("n", "<C-n>", ":NvimTreeToggle<CR>", opts)

-- Telescope mappings
vim.keymap.set("n", "<C-p>", function() require("telescope.builtin").find_files() end, opts)
vim.keymap.set("n", "<leader>b>", function() require("telescope.builtin").buffers() end, opts)
vim.keymap.set("n", "<leader>g", function() require("telescope.builtin").live_grep() end, opts)
vim.keymap.set("n", "<C-b>", function() require("telescope.builtin").buffers() end, opts)

-- Comment toggle (Ctrl+/)
vim.keymap.set("n", "<C-_>", "gcc", { remap = true, silent = true })
vim.keymap.set("v", "<C-_>", "gc", { remap = true, silent = true })

-- Filetype indent
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "javascript","javascriptreact","typescript","typescriptreact" },
    callback = function() 
        vim.bo.shiftwidth = 2
        vim.bo.tabstop = 2
        vim.bo.softtabstop = 2
        vim.bo.expandtab = true
    end,
})

-- Hop
vim.keymap.set("n", "f", ":HopChar1<CR>", opts)
vim.keymap.set("n", "F", ":HopWord<CR>", opts)

-- Yank/Cut
vim.keymap.set("n", "<leader>y", "ggVG\"+y", opts)
vim.keymap.set("n", "<leader>x", "ggVG\"+x", opts)

-- Triforce shortcuts
vim.keymap.set("n", "<C-t>p", function() require("triforce").show_profile() end, opts)
vim.keymap.set("n", "<C-t>s", function() require("triforce").get_stats() end, opts)
vim.keymap.set("n", "<C-t>r", function() require("triforce").reset_stats() end, opts)
vim.keymap.set("n", "<C-t>S", function() require("triforce").save_stats() end, opts)
vim.keymap.set("n", "<C-t>d", function() require("triforce").debug_languages() end, opts)

-- Quick import sort
vim.keymap.set("n", "<leader>ri", function() 
    local file = vim.fn.expand("%")
    if vim.fn.executable("npx") == 1 and vim.fn.executable("eslint") == 1 then
        vim.cmd("!" .. "npx eslint --fix " .. file)
    else
        vim.notify("npx or eslint not found", vim.log.levels.WARN)
    end
end, { silent=true })

-- =========================
-- Transparency toggle
-- =========================
local M = {}
local original_scheme = "carbonfox"

M.transparency_on = function() 
    local groups = {
        "Normal", "NormalNC", "VertSplit", "StatusLine", "StatusLineNC",
        "Pmenu", "TelescopeNormal", "TelescopeBorder", "NvimTreeNormal",
        "Terminal", "ToggleTerm"
    }
    for _, group in ipairs(groups) do
        vim.cmd(string.format("hi %s guibg=NONE ctermbg=NONE", group))
    end
    vim.opt.termguicolors = true
    print("Transparency ON")
end

M.transparency_off = function() 
    vim.cmd("colorscheme " .. original_scheme)
    print("Transparency OFF")
end

vim.api.nvim_create_user_command("Trans", M.transparency_on, {})
vim.api.nvim_create_user_command("TransOff", M.transparency_off, {})

M.toggle = false
vim.api.nvim_create_user_command("TransToggle", function() 
    if M.toggle then M.transparency_off() else M.transparency_on() end
    M.toggle = not M.toggle
end, {})

-- Colorscheme
vim.cmd("colorscheme carbonfox")

-- Indentation
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.scrolloff = 8 

M.transparency_on() -- Enable transparency on startup
