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
vim.opt.scrolloff = 8

-- =========================
-- Lazy-loaded Plugins
-- ========================

require("lazy").setup({
    spec = {
        "rafcamlet/nvim-whid",
        "windwp/nvim-autopairs",
        {
            'hrsh7th/nvim-cmp',
            dependencies = {
                'nvim-lua/completion-nvim', -- This is often a source for nvim-cmp
                'hrsh7th/cmp-nvim-lsp',
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-path',
            },
            config = function()
                local cmp = require('cmp')
                cmp.setup({
                    mapping = cmp.mapping.preset.insert({
                        ['<C-n>'] = cmp.mapping.select_next_item(),
                        ['<C-Space>'] = cmp.mapping.complete(),
                        ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    }),
                    sources = cmp.config.sources({
                        { name = 'nvim_lsp' },
                        { name = 'buffer' },
                        { name = 'path' },
                    }),
                })
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
        "nvim-lua/completion-nvim",
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

