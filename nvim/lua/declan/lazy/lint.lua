return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	cond = function()
		return vim.fn.executable("vale") == 1
	end,
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			markdown = { "vale" },
			text = { "vale" },
		}
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
