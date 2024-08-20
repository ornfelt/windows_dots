-- useINS
--
-- Only required if you have packer configured as `opt`
-- vim.cmd [[packadd packer.nvim]]
return require('packer').startup(function()
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
     'nvim-lualine/lualine.nvim',
     requires = { 'kyazdani42/nvim-web-devicons', opt = true }
  }

  use 'preservim/nerdtree'
  use 'tiagofumo/vim-nerdtree-syntax-highlight'

  use 'vimwiki/vimwiki'
  use 'tpope/vim-surround'
  --use 'junegunn/fzf'
  use 'ibhagwan/fzf-lua'
  --use { "ibhagwan/fzf-lua",
  -- --requires = { "nvim-tree/nvim-web-devicons" } -- icon support
  -- -- or if using mini.icons/mini.nvim
  -- requires = { "echasnovski/mini.icons" }
  --}

  use 'tpope/vim-commentary'
  use 'junegunn/vim-emoji'
  use 'vim-python/python-syntax'
  use 'norcalli/nvim-colorizer.lua'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-path'
  use 'hrsh7th/cmp-cmdline'
  use 'hrsh7th/nvim-cmp'
  use("gruvbox-community/gruvbox")

  use {
      'nvim-treesitter/nvim-treesitter',
      build = ':TSUpdate'
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }

  use({
      "ornfelt/ChatGPT.nvim",
      --config = function()
      --    require("chatgpt").setup()
      --end,
      requires = {
          "MunifTanjim/nui.nvim",
          --"nvim-lua/plenary.nvim",
          "folke/trouble.nvim",
          --"nvim-telescope/telescope.nvim"
      }
  })

  --use("robitx/gp.nvim")
  --use({
  --    "robitx/gp.nvim",
  --    config = function()
  --        require("gp").setup()
  --        or setup with your own config (see Install > Configuration in Readme)
  --        require("gp").setup(config)
  --        shortcuts might be setup here (see Usage > Shortcuts in Readme)
  --    end,
  --})

  use {
    "aznhe21/actions-preview.nvim",
    config = function()
      require("actions-preview").setup()
    end,
  }
  use 'nanotee/sqls.nvim'
  use 'preservim/nerdcommenter'
  -- use 'alexghergh/nvim-tmux-navigation'
  -- use 'mhinz/vim-startify'
  -- use 'mistweaverco/kulala.nvim'
  -- use '3rd/diagram.nvim'
  -- use 'lewis6991/gitsigns.nvim'
  -- use 'mechatroner/rainbow_csv'
  -- use("simrat39/rust-tools.nvim")
  -- use 'vim-syntastic/syntastic'
  -- use 'neoclide/coc.nvim'

end)
