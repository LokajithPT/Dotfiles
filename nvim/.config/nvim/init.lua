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
        "--depth=1",
        "https://github.com/folke/lazy.nvim.git",
        lazypath,
    })
end

vim.opt.rtp: prepend(lazypath)
vim.opt.termguicolors = true
vim.cmd("highlight Normal guibg=NONE ctermbg=NONE")

-- vim.opt.background = "dark"


-- =========================
-- General Settings
-- =========================

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = true
vim.opt.showmode = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 8

-- =========================
-- Lazy-loaded Plugins
-- ========================
--
--require("popup")
-- duolevelling of this shit -- 
--
--
local duo = require("duo")

vim.api.nvim_create_autocmd("VimEnter" , {
	callback = function()
		-- Set up initial global variables
		vim.g.duo_keystrokes_current = 0
		vim.g.duo_keystrokes_today = 0
		vim.g.duo_current_streak = 0
		vim.g.duo_current_level = 1
		vim.g.duo_freezes_left = 3
		vim.g.duo_streak_status = "pending"
		
		duo.start_heartbeat()
	end, 
})

vim.api.nvim_create_user_command("DuoOn", function ()
	duo.start_heartbeat()
	
end , {desc = "start duo HeartBeat "})

vim.api.nvim_create_user_command("DuoOff" , function ()
	duo.stop_heartbeat()
end, {desc = "stop duo HeartBeat"})

vim.api.nvim_create_user_command("DuoProfile", function ()
	require("duo").show_profile_window()
	
end, {desc = "profile shit "})

vim.api.nvim_create_user_command("DuoRefresh", function ()
	vim.notify("Refreshing Duo data...", vim.log.levels.INFO, {title = "Duo"})
	require("duo").fetch_dashboard_data()
	
end, {desc = "refresh duo data "})

require("lazy").setup({
    spec = {
        "rafcamlet/nvim-whid",
        {
            "windwp/nvim-autopairs",
            config = function()
                require("nvim-autopairs").setup({})
            end,
        },
        {
            'hrsh7th/nvim-cmp',
            dependencies = {
                'hrsh7th/cmp-nvim-lsp',
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-path',
                'L3MON4D3/LuaSnip', -- For snippet support
                'saadparwaiz1/cmp_luasnip',
            },
            config = function()
                local cmp = require('cmp')
                local luasnip = require('luasnip') -- Assuming luasnip will be used for snippets

                local check_backspace = function()
                    local col = vim.fn.col('.') - 1
                    return col == 0 or vim.fn.getline('.'):sub(col, col):match('%s')
                end

                local has_words_before = function()
                  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then return false end
                  return vim.fn.col('.') ~= 1 and vim.fn.getline('.'):sub(vim.fn.col('.')-1, vim.fn.col('.')-1):match('%S')
                end

                cmp.setup({
                    snippet = {
                        -- REQUIRED - This is used as replacement for expanding snippets of active completion items.
                        expand = function(args)
                            luasnip.lsp_expand(args.body) -- For `luasnip` users.
                        end,
                    },
                    mapping = cmp.mapping.preset.insert({
                        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                        ['<C-f>'] = cmp.mapping.scroll_docs(4),
                        ['<C-Space>'] = cmp.mapping.complete(),
                        ['<C-e>'] = cmp.mapping.abort(),
                        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
                        ['<Tab>'] = cmp.mapping(function(fallback)
                            if cmp.visible() then
                                cmp.select_next_item()
                            elseif luasnip.expand_or_jumpable() then
                                luasnip.expand_or_jump()
                            elseif has_words_before() then
                                cmp.complete()
                            else
                                fallback()
                            end
                        end, { 'i', 's' }),

                        ['<S-Tab>'] = cmp.mapping(function(fallback)
                            if cmp.visible() then
                                cmp.select_prev_item()
                            elseif luasnip.jumpable(-1) then
                                luasnip.jump(-1)
                            else
                                fallback()
                            end
                        end, { 'i', 's' }),
                    }),
                    sources = cmp.config.sources({
                        { name = 'nvim_lsp' },
                        { name = 'luasnip' }, -- Added for snippet suggestions
                        { name = 'buffer' },
                        { name = 'path' },
                    }),
                    formatting = {
                        format = function(entry, vim_item)
                            -- Kind icons
                            vim_item.kind = string.format('%s %s', require('nvim-web-devicons').get_icon(entry.kind), vim_item.kind)
                            -- Source
                            vim_item.menu = ({
                                nvim_lsp = '[LSP]',
                                luasnip = '[Snippet]', -- Added for snippet source
                                buffer = '[Buffer]',
                                path = '[Path]',
                            })[entry.source.name]
                            return vim_item
                        end,
                    },
                    window = {
                        completion = cmp.config.window.bordered({
                            col_offset = -3,
                            side_padding = 0,
                        }),
                        documentation = cmp.config.window.bordered({
                            col_offset = -3,
                            side_padding = 0,
                        }),
                    },
                })
            end,
        },
        {
            'L3MON4D3/LuaSnip',
            config = function()
                require('luasnip').setup({})
            end,
        },
        "nvim-tree/nvim-web-devicons",
        {
            'nvim-tree/nvim-tree.lua',
            lazy = false, -- nvim-tree should not be lazy loaded for a toggle mapping
            config = function()
                -- setup with defaults
                require("nvim-tree").setup {
                    view = {
                        width = 30,
                    },
                    git = {
                        enable = true,
                        ignore = false,
                    },
                    renderer = {
                        group_empty = true,
                    },
                    filters = {
                        dotfiles = true,
                    },
                }

                -- set keymaps
                vim.keymap.set('n', '<C-n>', '<cmd>NvimTreeToggle<CR>', { noremap = true, silent = true })
            end,
        },

        {
            'nvim-telescope/telescope.nvim',
            dependencies = { 'nvim-lua/plenary.nvim' }, -- Telescope requires plenary
            config = function()
                local telescope = require('telescope')
                telescope.setup({
                    defaults = {
                        -- Default configuration for all pickers goes here:
                    },
                    pickers = {
                        -- Configuration for specific pickers goes here:
                        find_files = {
                            -- Example: Don't show hidden files in find_files
                            -- show_hidden = false,
                        },
                    },
                })
                -- Map <Leader>p to find files
                vim.keymap.set('n', '<C-p>', '<cmd>Telescope find_files<CR>', { noremap = true, silent = true })
            end,
        },

        {
            'williamboman/mason.nvim',
            config = function()
                require('mason').setup()
            end,
        },
        "kats-vim/which-key.nvim",
        "linrongbin16/lsp-progress.nvim",
        {
            'neovim/nvim-lspconfig',
            dependencies = {
                'williamboman/mason.nvim',
                'williamboman/mason-lspconfig.nvim',
            },
            config = function()
                local capabilities = require("cmp_nvim_lsp").default_capabilities()

                local on_attach = function(client, bufnr)
                    -- Enable completion triggered by <c-x><c-o>
                    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

                    -- Mappings.
                    local opts = { noremap=true, silent=true }
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>f', '<cmd>lua vim.lsp.buf.format()<CR>', opts)
                end

                require("mason-lspconfig").setup({
                    -- List of servers to ensure are installed. Mason will automatically
                    -- install them as you open files of that type if not present.
                    ensure_installed = { "lua_ls", "jsonls", "html", "cssls", "ts_ls", "pyright", "rust_analyzer", "gopls", "clangd" },
                    handlers = {
                        -- This is the default handler that will be applied to all servers
                        function(server_name)
                            require("lspconfig")[server_name].setup({
                                capabilities = capabilities,
                                on_attach = on_attach,
                            })
                        end,
                        -- You can add specific handlers for individual servers here if needed.
                    },
                })
            end,
        },
        "saadpar/indent-blankline.nvim",
        {
            'mbbill/undotree',
            config = function()
                vim.keymap.set('n', '<Leader>u', vim.cmd.UndotreeToggle, { noremap = true, silent = true })
            end,
        }
    }
}


    -- Add your other existing plugins...
    -- (your other lazy.nvim plugins would go here)

)

