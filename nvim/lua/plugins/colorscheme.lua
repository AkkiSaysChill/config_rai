return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },
  { "catppuccin/nvim" },
  { "akinsho/bufferline.nvim" },
  { "rebelot/kanagawa.nvim" },
  { "bluz71/vim-moonfly-colors" },
  { "uloco/bluloco.nvim" },
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
