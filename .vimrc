" Place in ~/
" or $HOME/ or h:\ or %userprofile%
" Use :set vimrc in VS to see path

"set clipboard=unnamedplus
set clipboard=unnamed
" in vscode use this instead: "vim.useSystemClipboard": true
" or: ctrl+, -> search vim -> Enable Vim: Use System Clipboard
vnoremap <C-c> y

"Use 'set rnu' only for vscode...
"set nu rnu
set number

" Enable highlighting of the current line
set cursorline

" Use spaces instead of tabs
set expandtab

" Use intelligent tabbing
set smarttab

" Enable auto-indenting
set autoindent

" Enable smart auto-indenting with syntax support
set smartindent

" Ignore case when searching
set ignorecase

" Round indent to multiple of shiftwidth
set shiftround

" Highlight search results
set hlsearch

" Incremental search that shows partial matches
set incsearch

vnoremap < <gv
vnoremap > >gv
noremap Y y$
let mapleader = ' '
noremap <leader>p viw"_dP
vnoremap <leader>d "_d
nnoremap <leader>d "_d

" VS keybinds (use vim for all, then set these manually):
" m-x: Debug.Start
" m-d: Edit.GoToDefinition
" m-s-d: Edit.GoToImplementation
" m-r: Edit.FinadAllReferences
" m-s-r: Refactor.Rename
" m-a: Edit.GoToFile
" m-f: Edit.FindinFiles
" m-s-f: Edit.ReplaceinFiles
" m-n: Project.ManageNuGetPackages
" c-r Edit.Redo
" c-f Edit.Find
" c-k c-c Edit.ToggleLineComment