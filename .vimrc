" Place in ~/
" or $HOME/ or h:\ or %userprofile%
" Use :set vimrc in VS to see path
set ignorecase
"set clipboard=unnamedplus
set clipboard=unnamed
" in vscode use this instead: "vim.useSystemClipboard": true
" or: ctrl+, -> search vim -> Enable Vim: Use System Clipboard
vnoremap <C-c> y
set rnu
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
" m-c-d: Edit.GoToImplementation
" m-r: Edit.FinadAllReferences
" m-s-r: Refactor.Rename
" m-a: Edit.GoToFile
" m-f: Edit.FindinFiles
" m-s-f: Edit.ReplaceinFiles
" m-n: Project.ManageNuGetPackages
" c-r Edit.Redo
" c-f Edit.Find
" c-k c-c Edit.ToggleLineComment