return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	lazy = false,
	dependencies = {
		{
			"nvim-treesitter/nvim-treesitter-textobjects",
			branch = "main",
			config = function()
				local textobjects = require("nvim-treesitter-textobjects")
				textobjects.setup({
					select = {
						lookahead = true,
						selection_modes = {
							["@parameter.outer"] = "v",
							["@function.outer"] = "V",
							["@class.outer"] = "V",
						},
					},
					move = { set_jumps = true },
				})

				local select = require("nvim-treesitter-textobjects.select")
				local move = require("nvim-treesitter-textobjects.move")
				local function map(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { desc = desc })
				end

				map({ "x", "o" }, "af", function()
					select.select_textobject("@function.outer", "textobjects")
				end, "Around function")
				map({ "x", "o" }, "if", function()
					select.select_textobject("@function.inner", "textobjects")
				end, "Inside function")
				map({ "x", "o" }, "ac", function()
					select.select_textobject("@class.outer", "textobjects")
				end, "Around class/type")
				map({ "x", "o" }, "ic", function()
					select.select_textobject("@class.inner", "textobjects")
				end, "Inside class/type")
				map({ "x", "o" }, "aa", function()
					select.select_textobject("@parameter.outer", "textobjects")
				end, "Around argument")
				map({ "x", "o" }, "ia", function()
					select.select_textobject("@parameter.inner", "textobjects")
				end, "Inside argument")

				map({ "n", "x", "o" }, "]m", function()
					move.goto_next_start("@function.outer", "textobjects")
				end, "Next function start")
				map({ "n", "x", "o" }, "[m", function()
					move.goto_previous_start("@function.outer", "textobjects")
				end, "Previous function start")
				map({ "n", "x", "o" }, "]M", function()
					move.goto_next_end("@function.outer", "textobjects")
				end, "Next function end")
				map({ "n", "x", "o" }, "[M", function()
					move.goto_previous_end("@function.outer", "textobjects")
				end, "Previous function end")
				map({ "n", "x", "o" }, "]]", function()
					move.goto_next_start("@class.outer", "textobjects")
				end, "Next class/type")
				map({ "n", "x", "o" }, "[[", function()
					move.goto_previous_start("@class.outer", "textobjects")
				end, "Previous class/type")
			end,
		},
	},
}
