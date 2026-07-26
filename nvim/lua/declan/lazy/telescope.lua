return {
    'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
    },
    config = function()
        local telescope = require('telescope')
        telescope.setup({
            defaults = {
                -- keep the picker from wading through vendored/build dirs in the monorepo
                file_ignore_patterns = { '%.git/', 'node_modules/', 'dist/', 'target/' },
            },
        })
        -- activate the compiled C sorter (dep is built but was never loaded before,
        -- so telescope silently fell back to the slow pure-lua fzy sorter)
        telescope.load_extension('fzf')
    end,
    keys = {
        { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
        { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live grep' },
        { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
        { '<leader>fr', '<cmd>Telescope git_files<cr>', desc = 'Git files (repo)' },
        { '<leader>fs', function()
            require('telescope.builtin').grep_string({ search = vim.fn.input("Grep > ") })
        end, desc = 'Grep string' },
    },
}
