-- Minimal Neovim setup for Asura.
-- Clean UI, Wayland clipboard, fast navigation, and Codex in a floating terminal.

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.termguicolors = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 200
opt.timeoutlen = 350
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.undofile = true
opt.confirm = true
opt.laststatus = 3
opt.showtabline = 2
opt.showmode = false
opt.cmdheight = 1
opt.winborder = "rounded"
opt.pumheight = 12
opt.wildmenu = true
opt.wildmode = { "longest:full", "full" }
opt.wildoptions = { "pum", "fuzzy" }
opt.fillchars = { eob = " " }

pcall(function()
  opt.autocomplete = true
end)

pcall(function()
  opt.completeopt = { "menu", "menuone", "noselect", "popup", "fuzzy" }
end)

if vim.fn.executable("wl-copy") == 1 and vim.fn.executable("wl-paste") == 1 then
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = {
      ["+"] = { "wl-copy", "--type", "text/plain" },
      ["*"] = { "wl-copy", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = { "wl-paste", "--no-newline" },
      ["*"] = { "wl-paste", "--primary", "--no-newline" },
    },
    cache_enabled = true,
  }
end

vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "*" },
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local function close_buffer(bufnr, force)
  bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
  force = force or false

  if vim.bo[bufnr].modified and not force then
    vim.notify("Buffer has unsaved changes. Use <leader>Q to quit all or save first.", vim.log.levels.WARN)
    return
  end

  local ok, bufremove = pcall(require, "mini.bufremove")
  if ok then
    bufremove.delete(bufnr, force)
    return
  end

  vim.cmd((force and "bdelete! " or "bdelete ") .. bufnr)
end

require("lazy").setup({
  {
    "rose-pine/neovim",
    name = "rose-pine",
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "moon",
        dark_variant = "moon",
        styles = { bold = true, italic = false, transparency = false },
        highlight_groups = {
          Normal = { bg = "#120d12", fg = "#f3e7ee" },
          NormalFloat = { bg = "#19121a", fg = "#f3e7ee" },
          FloatBorder = { fg = "#ff9db5", bg = "#19121a" },
          CursorLine = { bg = "#201821" },
          CursorLineNr = { fg = "#ff9db5", bold = true },
          LineNr = { fg = "#8f7882" },
          ColorColumn = { bg = "#19121a" },
          Visual = { bg = "#533041" },
          Search = { bg = "#f5c06f", fg = "#120d12" },
          IncSearch = { bg = "#ff9db5", fg = "#120d12" },
          MatchParen = { fg = "#ffadd7", bg = "#342332", bold = true },
          Pmenu = { bg = "#211923", fg = "#f3e7ee" },
          PmenuSel = { bg = "#ff9db5", fg = "#120d12", bold = true },
          PmenuSbar = { bg = "#211923" },
          PmenuThumb = { bg = "#9a7b88" },
          WinSeparator = { fg = "#2b202d", bg = "#120d12" },
          SignColumn = { bg = "#120d12" },
          StatusLine = { bg = "#4b474e", fg = "#f3e7ee" },
          StatusLineNC = { bg = "#353138", fg = "#9a7b88" },
          MsgArea = { bg = "#4b474e", fg = "#f3e7ee" },
          ModeMsg = { fg = "#ff9db5", bold = true },
          DiagnosticError = { fg = "#ff6078" },
          DiagnosticWarn = { fg = "#f3c46f" },
          DiagnosticInfo = { fg = "#78aefc" },
          DiagnosticHint = { fg = "#9fd67a" },
          NeoTreeNormal = { bg = "#0d0910", fg = "#dccbd3" },
          NeoTreeNormalNC = { bg = "#0d0910", fg = "#dccbd3" },
          NeoTreeDirectoryName = { fg = "#d9b8ff" },
          NeoTreeDirectoryIcon = { fg = "#d9b8ff" },
          NeoTreeFileNameOpened = { fg = "#fff6f9", bold = true },
          NeoTreeGitModified = { fg = "#f3c46f" },
          NeoTreeGitUntracked = { fg = "#9fd67a" },
          NeoTreeIndentMarker = { fg = "#6b3d62" },
          NeoTreeWinSeparator = { fg = "#211923", bg = "#0d0910" },
        },
      })
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local asura_theme = {
        normal = {
          a = { fg = "#120d12", bg = "#f3e7ee", gui = "bold" },
          b = { fg = "#f3e7ee", bg = "#5a5660" },
          c = { fg = "#d8c7d1", bg = "#4b474e" },
        },
        insert = {
          a = { fg = "#120d12", bg = "#9fd67a", gui = "bold" },
          b = { fg = "#f3e7ee", bg = "#5a5660" },
          c = { fg = "#d8c7d1", bg = "#4b474e" },
        },
        visual = {
          a = { fg = "#120d12", bg = "#ffadd7", gui = "bold" },
          b = { fg = "#f3e7ee", bg = "#5a5660" },
          c = { fg = "#d8c7d1", bg = "#4b474e" },
        },
        replace = {
          a = { fg = "#120d12", bg = "#ff6078", gui = "bold" },
          b = { fg = "#f3e7ee", bg = "#5a5660" },
          c = { fg = "#d8c7d1", bg = "#4b474e" },
        },
        command = {
          a = { fg = "#120d12", bg = "#f3c46f", gui = "bold" },
          b = { fg = "#f3e7ee", bg = "#5a5660" },
          c = { fg = "#d8c7d1", bg = "#4b474e" },
        },
        inactive = {
          a = { fg = "#a796a0", bg = "#353138" },
          b = { fg = "#a796a0", bg = "#353138" },
          c = { fg = "#a796a0", bg = "#353138" },
        },
      }

      local function lsp_name()
        local clients = vim.lsp.get_clients({ bufnr = 0 })
        if #clients == 0 then return "LSP off" end
        return "LSP " .. clients[1].name
      end

      local function buffer_count()
        return tostring(#vim.fn.getbufinfo({ buflisted = 1 }))
      end

      require("lualine").setup({
        options = {
          theme = asura_theme,
          globalstatus = true,
          component_separators = "",
          section_separators = { left = "", right = "" },
          disabled_filetypes = { statusline = { "dashboard", "lazy" } },
        },
        sections = {
          lualine_a = { { "mode", fmt = function(s) return " " .. s .. " " end } },
          lualine_b = {
            { "filename", path = 0, symbols = { modified = " ●", readonly = " lock" } },
            { "branch", icon = "main" },
            { buffer_count, icon = "buf" },
          },
          lualine_c = { { "diff", symbols = { added = "+", modified = "~", removed = "-" } } },
          lualine_x = {
            { "diagnostics", symbols = { error = "E ", warn = "W ", info = "I ", hint = "H " } },
            { lsp_name },
            { "filetype", icon_only = false },
          },
          lualine_y = { { "progress" } },
          lualine_z = { { "location" } },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", path = 0 } },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { "neo-tree", "lazy", "mason", "fzf" },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          always_show_bufferline = true,
          close_command = function(bufnr) close_buffer(bufnr, false) end,
          right_mouse_command = function(bufnr) close_buffer(bufnr, false) end,
          middle_mouse_command = function(bufnr) close_buffer(bufnr, false) end,
          show_close_icon = false,
          show_buffer_close_icons = true,
          close_icon = "×",
          modified_icon = "●",
          separator_style = { "", "" },
          indicator = { style = "underline" },
          offsets = {
            {
              filetype = "neo-tree",
              text = " files",
              text_align = "left",
              separator = true,
            },
          },
        },
        highlights = {
          fill = { bg = "#120d12" },
          background = { fg = "#9a7b88", bg = "#1a131b" },
          buffer_visible = { fg = "#d8c7d1", bg = "#1a131b" },
          buffer_selected = { fg = "#fff6f9", bg = "#241b25", bold = true, italic = false },
          close_button = { fg = "#9a7b88", bg = "#1a131b" },
          close_button_visible = { fg = "#9a7b88", bg = "#1a131b" },
          close_button_selected = { fg = "#ffa7a7", bg = "#241b25", bold = true },
          indicator_selected = { fg = "#ff9db5", bg = "#241b25" },
          modified = { fg = "#f5c06f", bg = "#1a131b" },
          modified_visible = { fg = "#f5c06f", bg = "#1a131b" },
          modified_selected = { fg = "#f5c06f", bg = "#241b25" },
          separator = { fg = "#120d12", bg = "#1a131b" },
          separator_visible = { fg = "#120d12", bg = "#1a131b" },
          separator_selected = { fg = "#120d12", bg = "#241b25" },
          tab = { fg = "#9a7b88", bg = "#1a131b" },
          tab_selected = { fg = "#fff6f9", bg = "#241b25" },
        },
      })
    end,
  },
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("fzf-lua").setup({
        winopts = {
          height = 0.82,
          width = 0.88,
          row = 0.5,
          col = 0.5,
          border = "rounded",
          preview = { layout = "flex", vertical = "down:45%" },
        },
        keymap = { fzf = { ["ctrl-q"] = "select-all+accept" } },
      })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        sources = { "filesystem", "buffers", "git_status" },
        enable_git_status = true,
        enable_diagnostics = true,
        default_component_configs = {
          indent = {
            indent_size = 2,
            padding = 1,
            with_markers = true,
            with_expanders = true,
          },
          icon = { folder_closed = "", folder_open = "", folder_empty = "" },
          name = { use_git_status_colors = true },
          modified = { symbol = "●" },
          git_status = {
            symbols = {
              added = "✚",
              deleted = "✖",
              modified = "",
              renamed = "󰁕",
              untracked = "",
              ignored = "",
              unstaged = "",
              staged = "",
              conflict = "",
            },
          },
        },
        window = {
          position = "left",
          width = 30,
          mappings = {
            ["<space>"] = "none",
            ["o"] = "open",
            ["l"] = "open",
            ["h"] = "close_node",
            ["s"] = "open_split",
            ["v"] = "open_vsplit",
          },
        },
        filesystem = {
          bind_to_cwd = true,
          follow_current_file = { enabled = true, leave_dirs_open = true },
          hijack_netrw_behavior = "open_current",
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            never_show = { ".DS_Store", "thumbs.db" },
          },
        },
      })
    end,
  },
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.ai").setup()
      require("mini.bufremove").setup({ silent = true })
      require("mini.pairs").setup()
      require("mini.surround").setup()
      require("mini.indentscope").setup({
        symbol = "|",
        options = { try_as_border = true },
      })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "|" },
          change = { text = "|" },
          delete = { text = "_" },
          topdelete = { text = "^" },
          changedelete = { text = "|" },
        },
      })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "modern",
        delay = 250,
        win = { border = "rounded" },
      })
    end,
  },
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate", "MasonLog" },
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "OK",
          package_pending = "...",
          package_uninstalled = "--",
        },
      },
    },
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local configs = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        },
        bashls = {},
        jsonls = {},
        yamlls = {},
        marksman = {},
        pyright = {},
        ts_ls = {},
      }

      for server, config in pairs(configs) do
        vim.lsp.config(server, config)
      end

      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_enable = true,
      })
    end,
  },
}, {
  ui = {
    border = "rounded",
    icons = {
      cmd = ">",
      config = "cfg",
      event = "event",
      ft = "ft",
      init = "init",
      keys = "key",
      plugin = "plug",
      runtime = "run",
      source = "src",
      start = "start",
      task = "task",
      lazy = "lazy",
    },
  },
  change_detection = { notify = false },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

map("n", "<leader>w", "<cmd>w<cr>", "Save")
map("n", "<leader>q", function() close_buffer(0, false) end, "Close file")
map("n", "<leader>Q", "<cmd>qa<cr>", "Quit Neovim")
map("n", "<leader>h", "<cmd>nohlsearch<cr>", "Clear search")
map("n", "<leader>ff", function() require("fzf-lua").files() end, "Find files")
map("n", "<leader>fg", function() require("fzf-lua").live_grep() end, "Live grep")
map("n", "<leader>fb", function() require("fzf-lua").buffers() end, "Buffers")
map("n", "<leader>fr", function() require("fzf-lua").oldfiles() end, "Recent files")
map("n", "<leader>gg", function() require("fzf-lua").git_status() end, "Git status")
map("n", "<leader>e", "<cmd>Neotree toggle reveal position=left<cr>", "File explorer")
map("n", "<leader>E", "<cmd>Neotree reveal_file=%:p reveal_force_cwd position=left<cr>", "Reveal current file")
map("n", "<leader>be", "<cmd>Neotree buffers position=float<cr>", "Buffer explorer")
map("n", "<leader>ge", "<cmd>Neotree git_status position=float<cr>", "Git explorer")
map("n", "<leader>xl", "<cmd>Lazy<cr>", "Plugin manager")
map("n", "<leader>xs", "<cmd>Lazy sync<cr>", "Sync plugins")
map("n", "<leader>xu", "<cmd>Lazy update<cr>", "Update plugins")
map("n", "<leader>xm", "<cmd>Mason<cr>", "Extension manager")
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", "Next buffer")
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", "Previous buffer")
map("n", "<leader>d", vim.diagnostic.open_float, "Line diagnostics")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
map("t", "<esc><esc>", [[<c-\><c-n>]], "Terminal normal mode")

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local opts = { buffer = event.buf, silent = true }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
    vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
    vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover docs" }))
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
    vim.keymap.set("n", "<leader>cf", function()
      vim.lsp.buf.format({ async = true })
    end, vim.tbl_extend("force", opts, { desc = "Format buffer" }))
  end,
})

local function open_float_term(cmd, title)
  local width = math.floor(vim.o.columns * 0.88)
  local height = math.floor(vim.o.lines * 0.82)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  vim.wo[win].winhl = "Normal:NormalFloat,FloatBorder:FloatBorder"
  vim.fn.termopen(cmd, { cwd = vim.fn.getcwd() })
  vim.cmd.startinsert()
end

local function codex_cmd(args)
  if vim.fn.executable("codex") ~= 1 then
    vim.notify("codex is not in PATH", vim.log.levels.ERROR)
    return
  end

  local cmd = { "codex", "-C", vim.fn.getcwd() }
  for arg in vim.gsplit(args or "", "%s+") do
    if arg ~= "" then table.insert(cmd, arg) end
  end
  open_float_term(cmd, "Codex")
end

vim.api.nvim_create_user_command("Codex", function(opts)
  codex_cmd(opts.args)
end, { nargs = "*", desc = "Open Codex in a floating terminal" })

vim.api.nvim_create_user_command("CodexFile", function()
  local file = vim.fn.expand("%:p")
  local prompt = file ~= "" and ("Help me with this file: " .. file) or "Help me with this project"
  open_float_term({ "codex", "-C", vim.fn.getcwd(), prompt }, "Codex File")
end, { desc = "Ask Codex about the current file" })

vim.api.nvim_create_user_command("CodexReview", function()
  open_float_term({ "codex", "-C", vim.fn.getcwd(), "review" }, "Codex Review")
end, { desc = "Run Codex review for the current project" })

map("n", "<leader>ac", "<cmd>Codex<cr>", "Codex")
map("n", "<leader>af", "<cmd>CodexFile<cr>", "Codex current file")
map("n", "<leader>ar", "<cmd>CodexReview<cr>", "Codex review")

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if #vim.api.nvim_list_uis() == 0 then return end

    if vim.fn.argc() == 0 then
      vim.cmd("silent! Neotree show position=left")
    else
      vim.cmd("silent! Neotree reveal position=left")
    end
  end,
})

vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-n>" end
  return "<Tab>"
end, { expr = true, silent = true, desc = "Next completion" })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then return "<C-p>" end
  return "<C-h>"
end, { expr = true, silent = true, desc = "Previous completion" })

vim.keymap.set("i", "<C-Space>", "<C-n>", { silent = true, desc = "Open completion menu" })
vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then return "<C-y>" end
  return "<CR>"
end, { expr = true, silent = true, desc = "Accept completion" })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
  end,
})
