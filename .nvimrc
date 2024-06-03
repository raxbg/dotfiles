set nofixeol

set expandtab       " Use spaces instead of tabs
set tabstop=4       " Number of spaces tabs count for
set shiftwidth=4    " Number of spaces to use for autoindent
set softtabstop=4   " Number of spaces to insert for a tab

map <C-n> :Neotree toggle<CR>
map <C-o> :Neotree reveal %<CR>
map <C-h> :tabp<CR>
map <C-l> :tabn<CR>
map <C-j> <C-F>
map <C-k> <C-U>
map _ ddp
map + ddkP
nnoremap Q q
map q :q<CR>
map W :w<CR>
map <F4> mzgg=G`z
"map <S-t> :bo ter ++rows=15<CR>

"Split movement
map <S-h> <C-w>H
map <S-l> <C-w>L
