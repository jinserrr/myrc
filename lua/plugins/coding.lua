local tab = function(fallback)
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  if cmp.visible() then
    cmp.confirm({ select = true })
  elseif luasnip.expand_or_jumpable() then
    luasnip.expand_or_jump()
  else
    fallback()
  end
end

local s_tab = function(fallback)
  local luasnip = require("luasnip")

  if luasnip.jumpable(-1) then
    luasnip.jump(-1)
  else
    fallback()
  end
end

local has_words_before = function()
  if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
    return false
  end
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local next = function(fallback)
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  if cmp.visible() then
    cmp.select_next_item()
  elseif luasnip.expandable() then
    luasnip.expand()
  elseif has_words_before() then
    cmp.complete()
  elseif luasnip.jumpable() then
    luasnip.jump(1)
  else
    fallback()
  end
end

local prev = function(fallback)
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  if cmp.visible() then
    cmp.select_prev_item()
  elseif luasnip.jumpable(-1) then
    luasnip.jump(-1)
  else
    fallback()
  end
end

return {
  -- snippets
  {
    "L3MON4D3/LuaSnip",
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
    config = function(opts)
      require("luasnip").setup(opts)
      require("luasnip.loaders.from_snipmate").lazy_load()
    end
  },

  -- auto completion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
    },
    opts = function()
      local cmp = require("cmp")
      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        window = {
          completion = {
            border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
          },
          documentation = {
            border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
          },
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-w>"] = cmp.mapping.complete({}),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<Tab>"] = cmp.mapping(tab, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(s_tab, { "i", "s" }),
          ["<C-j>"] = cmp.mapping(next, { "i", "s" }),
          ["<C-k>"] = cmp.mapping(prev, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          fields = { "abbr", "kind", "menu" },
          format = function(entry, item)
            if string.len(item.abbr) > 24 then
              item.abbr = string.sub(item.abbr, 1, 24) .. "…"
            end

            local icons = require("config").icons.kinds
            if icons[item.kind] then
              item.kind = icons[item.kind] .. item.kind
            end

            item.menu = ({
              buffer = "[Buf]",
              nvim_lsp = "[LSP]",
              nvim_lua = "[Lua]",
              luasnip = "[Spt]",
              path = "[Pah]",
            })[entry.source.name]

            return item
          end,
        },
        experimental = {
          ghost_text = {
            hl_group = "LspCodeLens",
          },
        },
      }
    end,
  },

  -- auto pairs
  {
    "windwp/nvim-autopairs",
    event = "VeryLazy",
    config = function()
      require("nvim-autopairs").setup {}
    end
  },

  -- surround
  {
    "echasnovski/mini.surround",
    keys = function(plugin, keys)
      local opts = require("lazy.core.plugin").values(plugin, "opts", false)
      local mappings = {
        { opts.mappings.add, desc = "Add surrounding", mode = { "n", "v" } },
        { opts.mappings.delete, desc = "Delete surrounding" },
        { opts.mappings.find, desc = "Find right surrounding" },
        { opts.mappings.find_left, desc = "Find left surrounding" },
        { opts.mappings.highlight, desc = "Highlight surrounding" },
        { opts.mappings.replace, desc = "Replace surrounding" },
        { opts.mappings.update_n_lines, desc = "Update `MiniSurround.config.n_lines`" },
      }
      return vim.list_extend(mappings, keys, 1, #keys)
    end,
    opts = {
      mappings = {
        add = "gaa", -- Add surrounding in Normal and Visual modes
        delete = "gad", -- Delete surrounding
        find = "gaf", -- Find surrounding (to the right)
        find_left = "gaF", -- Find surrounding (to the left)
        highlight = "gah", -- Highlight surrounding
        replace = "gar", -- Replace surrounding
        update_n_lines = "gan", -- Update `n_lines`
      },
    },
    config = function(_, opts)
      require("mini.surround").setup(opts)
    end,
  },

  -- comments
  { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {
      hooks = {
        pre = function()
          require("ts_context_commentstring.internal").update_commentstring({})
        end,
      },
    },
    config = function(_, opts)
      require("mini.comment").setup(opts)
    end,
  },
}