set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'ervandew/supertab'
Plugin 'editorconfig/editorconfig-vim'
call vundle#end()

if !exists('g:vscode')
    call vundle#begin()
    "Plugin 'taglist.vim'
    Plugin 'scrooloose/nerdtree'
    Plugin 'scrooloose/syntastic'
    Plugin 'kien/ctrlp.vim'
    Plugin 'blerins/flattown'
    Plugin 'nathanaelkane/vim-indent-guides'
    "Plugin 'joonty/vdebug.git'
    Plugin 'vim-airline/vim-airline'
    "Plugin 'vim-airline/vim-airline-themes'
    "Plugin 'hhvm/vim-hack'
    Plugin 'tobyS/pdv'
    Plugin 'tobyS/vmustache'
    "Plugin 'SirVer/ultisnips'
    call vundle#end()

    "if has('nvim') 
    "    "source /usr/lib/python3.6/site-packages/powerline/bindings/vim/plugin/powerline.vim
    "else
    "    source /usr/lib/python3.6/site-packages/powerline/bindings/vim/plugin/powerline.vim
    "endif
    "source /usr/local/lib/python2.7/site-packages/powerline/bindings/vim/plugin/powerline.vim

    if has('gui_running')
        set guifont=Meslo\ LG\ S\ DZ\ Regular\ for\ Powerline
    endif

    set nu
    set laststatus=2
    set showtabline=2
    let g:user_emmet_leader_key='<C-Z>'
    let mapleader=','
    let g:pdv_template_dir = $HOME ."/.vim/bundle/pdv/templates_snip"

    syntax enable
    colorscheme flattown

    "Indent lines settings
    let g:indent_guides_auto_colors=0
    let g:indent_guides_guide_size=1
    let g:indent_guides_enable_on_vim_startup=1
    let g:indent_guides_exclude_filetypes = ['help', 'nerdtree']
    hi IndentGuidesEven ctermbg=238
    hi IndentGuidesOdd ctermbg=236
endif

set noshowmode
set backspace=indent,eol,start
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab

augroup filetypedetect
    au BufRead,BufNewFile *.tpl set filetype=html
augroup END

augroup filetypedetect
    au BufRead,BufNewFile *.twig set filetype=html
augroup END

"Configure indents
autocmd Filetype javascript,html,css,smarty,yml,yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd Filetype php setlocal ts=4 sts=4 sw=4 expandtab omnifunc=phpcomplete_extended#CompletePHP
autocmd Filetype c,c++,java setlocal ts=4 sts=4 sw=4 expandtab

filetype plugin indent on

"Autocomplete options
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags

"Custom mappings
map <C-n> :NERDTreeToggle<CR>
map <C-o> :NERDTree %<CR>
map <C-h> :tabp<CR>
map <C-l> :tabn<CR>
map <C-j> <C-F>
map <C-k> <C-U>
map _ ddp
map + ddkP
map q :q<CR>
map W :w<CR>
map <F1> :NERDTreeToggle<CR>
map <F2> :TlistToggle<CR>
map <F3> :set scb!<CR>
map <F4> mzgg=G`z
map <F11> :diffthis<CR>
map <F12> :diffoff<CR>
map <C-i> :call pdv#DocumentWithSnip()<CR>
map <S-t> :bo ter ++rows=15<CR>

if !exists('g:vscode')
    "Split movement
    map <S-h> <C-w>H
    map <S-l> <C-w>L
    map <S-j> <C-w>J
    map <S-k> <C-w>K

    "Split resizing
    "map <C-H> 5<C-w><
    "map <C-L> 5<C-w>>
    "map <C-J> 5<C-w>-
    "map <C-K> 5<C-w>+
endif