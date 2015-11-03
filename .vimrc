set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'kien/ctrlp.vim'
Plugin 'blerins/flattown'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'ervandew/supertab'
call vundle#end()

filetype plugin indent on
source /usr/local/lib/python2.7/site-packages/powerline/bindings/vim/plugin/powerline.vim

set nu
set laststatus=2
set showtabline=2
set noshowmode
set backspace=indent,eol,start
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab
let g:user_emmet_leader_key='<C-Z>'
let mapleader=','
syntax enable
colorscheme flattown

"Configure indents
autocmd Filetype javascript,html,css,smarty setlocal ts=2 sts=2 sw=2 expandtab
autocmd Filetype php setlocal ts=4 sts=4 sw=4 expandtab omnifunc=phpcomplete_extended#CompletePHP
autocmd Filetype c,c++,java setlocal ts=4 sts=4 sw=4 expandtab

"Autocomplete options
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

"Indent lines settings
let g:indent_guides_auto_colors=0
let g:indent_guides_guide_size=1
let g:indent_guides_enable_on_vim_startup=1
let g:indent_guides_exclude_filetypes = ['help', 'nerdtree']
hi IndentGuidesEven ctermbg=238
hi IndentGuidesOdd ctermbg=236

"Custom mappings
map <C-n> :NERDTreeToggle<CR>
map <C-o> :NERDTree %<CR>
map <C-h> :tabp<CR>
map <C-l> :tabn<CR>
map <C-j> <C-F>
map <C-k> <C-U>
map <C-m> o<Esc>
map <C-q> :tabe ~/.vimrc<CR>
map _ ddp
map + ddkP
map q :q<CR>
map W :w<CR>
map <F1> :echo @%<CR>
map <F4> mzgg=G`z
