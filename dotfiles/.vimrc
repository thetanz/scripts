set number
" use syntax color higlighting
syntax on
set ls=2
set showmode
" show partial command in status line
set showcmd
set ruler
set background=dark
map <silent><F11> :let &background = ( &background == "dark"? "light" : "dark" )<CR>
map <silent><F12> mzgg=G`z
set tabstop=4
set expandtab
set softtabstop=4
set shiftwidth=4
filetype indent on
set nocompatible
set history=2000

" make tabs, trailing whitespace, and EOL characters easy to spot.
set list
set listchars=tab:▸\ ,trail:·,eol:¬

" smoother display on fast network connections
set ttyfast

" smoother display on fast network connections
set ttyfast

" allow most motion keys to wrap
set whichwrap=b,s,<,>,[,],~

" smoother display on fast network connections
set ttyfast

" use only one space when using joing
set nojoinspaces

" add the following chars to the list that form pairs
set matchpairs+={:}

" show matching brackets by flickering cursor
set showmatch

" show matching brackets quicker than default
set matchtime=1

" wrap long lines
set wrap

" smooth scroll
set sidescroll=1

" allow visual block select everywhere
set virtualedit=block

" always show statusline
set laststatus=2

set statusline=%n\ %1*%h%f%*\ %=%<[%3lL,%2cC]\ %2p%%\ 0x%02B%r%m

" show ruler
set ruler
set rulerformat=%h%r%m%=%f

" do not highlight the current search pattern
set nohlsearch

" show the current filename and path in the term title
set title

" string to put at the start of lines that have been wrapped
set showbreak=↪

" Wildmenu completion
set wildmenu

" easy indentation in visual mode
" this keeps the visual selection active after indenting, which is usually lost
" after you indent it
vmap > >gv
vmap < <gv

" Use display movement with arrow keys for extra precision. Arrow keys will
" move up and down the next line in the display even if the line is wrapped.
" This is useful for navigating very long lines that you often find with
" automatically generated text such as HTML.
" This is not useful if you turn off wrap.
imap <up> <C-O>gk
imap <down> <C-O>gj
nmap <up> gk
nmap <down> gj
vmap <up> gk
vmap <down> gj

if has("gui_running")

    " no need for the menu bar, scrollbar or toolbar in the gui
    set guioptions-=m
    set guioptions-=T
    set guioptions-=r
    set guioptions-=R

    " maximize the window upon startup
    set lines=999 columns=999

endif


