local luasnip = require("luasnip")
local cmp = require("cmp")

-- functions {{{
local has_words_before = function()
	if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
		return false
	end
	local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local check_backspace = function()
	local col = vim.fn.col(".") - 1
	return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
end

local function T(str)
	return vim.api.nvim_replace_termcodes(str, true, true, true)
end


local tab = function()
    if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
    elseif cmp.visible() then
        cmp.confirm({ select = true })
    elseif check_backspace() then
        vim.fn.feedkeys(T("<Tab>"), "n")
    else
        local copilot_keys = vim.fn["copilot#Accept"]()
        if copilot_keys ~= "" then
            vim.api.nvim_feedkeys(copilot_keys, "i", true)
        else
            vim.fn.feedkeys(T("<Tab>"), "n")
        end
    end
end

local s_tab = function()
			if luasnip.jumpable(-1) then
				luasnip.jump(-1)
			end
		end

--- }}}

-- setup crates
vim.cmd([[autocmd FileType toml lua require("cmp").setup.buffer { sources = { { name = "crates" } } }]])

cmp.setup({
	snippet = {
		expand = function(args)
			require("luasnip").lsp_expand(args.body)
		end,
	},
	documentation = {
		border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
	},
	completion = {
		completeopt = "menu,menuone,noselect",
	},
	experimental = {
		ghost_text = false,
	},
	formatting = {
		format = function(entry, vim_item)
			local icons = require("kind.icons").icons
			vim_item.kind = icons[vim_item.kind]
			vim_item.menu = ({
				nvim_lsp = "[LSP]",
				nvim_lua = "[Lua]",
				luasnip = "[Snippet]",
				crates = "[Crates]",
				buffer = "[Buffer]",
				path = "[Path]",
                neorg = "[neorg]"
			})[entry.source.name]
			return vim_item
		end,
	},

    -- mapping {{{
	mapping = {
		["<C-d>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-w>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.close(),
		["<Tab>"] = cmp.mapping({
            i = tab,
            s = tab,
            c = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Replace }),
        }),
		["<S-Tab"] = cmp.mapping({
            i = s_tab,
            s = s_tab,
            c = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Replace }),
        }),

		["<C-j>"] = cmp.mapping(function()
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expandable() then
				luasnip.expand()
			elseif has_words_before() then
				cmp.complete()
			elseif luasnip.jumpable() then
				luasnip.jump(1)
			end
		end, {
			"i",
			"s",
		}),

		["<C-k>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, {
			"i",
			"s",
		}),
	},
    -- }}}

	sources = {
		{ name = "nvim_lsp" },
		{ name = "nvim_lua" },
		{ name = "luasnip" },
		{ name = "buffer" },
		{ name = "path" },
        { name = "neorg" },
	},
})

-- setup {{{
cmp.setup.cmdline(":", {
    sources = cmp.config.sources({
      { name = "path" }
    }, {
      { name = "cmdline" }
    })
  })

cmp.setup.cmdline("/", {
  sources = {
    { name = "buffer" }
  }
})
-- }}}