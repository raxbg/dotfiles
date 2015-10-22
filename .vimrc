set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'
Plugin 'Shougo/vimproc'
Plugin 'Shougo/unite.vim'
"Plugin 'm2mdas/phpcomplete-extended'
Plugin 'kien/ctrlp.vim'
Plugin 'mattn/emmet-vim'
Plugin 'stulzer/heroku-colorscheme'
Plugin 'idbrii/vim-sandydune'
Plugin 'blerins/flattown'
Plugin 'joonty/vdebug.git'
call vundle#end()
filetype plugin indent on

set nu
set cursorline
"set statusline=%t%=[%{strlen(&fenc)?&fenc:'none'},%{&ff}]\ %h%m%r\ %y\ %c,%l/%L\ %P
source /usr/local/lib/python2.7/site-packages/powerline/bindings/vim/plugin/powerline.vim
set laststatus=2
set showtabline=2
set noshowmode
set backspace=indent,eol,start
filetype plugin indent on
autocmd Filetype javascript setlocal ts=2 sts=2 sw=2 expandtab
autocmd Filetype php setlocal ts=4 sts=4 sw=4 expandtab omnifunc=phpcomplete_extended#CompletePHP
"let macvim_skip_colorscheme=1
let g:user_emmet_leader_key='<C-Z>'
syntax enable
colorscheme flattown

autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

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
