# vim: set ft=sh :
#
# bash_profile from SVN-CONFIG (Georg Wassen)
# 
# original file resides in checkout/config/home/scripts/bash_profile
# ~/scripts is a symlink
#
# here are the actual settings
#
# ~/.bashrc : source ~/.bash_profile
# ~/.bash_profile : source ~/scripts/bash_profile (this file)
#


# remap CAPS-LOCK key to Escape
# (for vi)
if [ _$TERM == _xterm -a _$DISPLAY != _ ]; then
    setxkbmap -model ms
    xmodmap ~/scripts/xmodmap-esc
fi

# append ~/bin and ~/scripts to PATH
export PATH=~/scripts.git:~/scripts:$PATH:~/bin:~/bin/dmd/bin

# set BASH keybindings and default editor to VIM
set -o vi
export VISUAL=vim
export EDITOR=vim

# History: don't record duplicated entries (make, make, make, make)
export HISTCONTROL=ignorespace:ignoredups
# ...and ignore "svn ci" to avoid unexpected commits when replaying from the history
export HISTIGNORE='svn ci*:ls'

# set limits
ulimit -c 400000        # max core dump size
#ulimit -v 2097152       # limit max. virtual Memory per process
                        # that was a dumb idea: some processes (Firefox, virtual box) kept
                        # crashing with no meaningful message.

# aliases
alias v='gvim'          # v is gvim (GUI)
alias vi='vim'          # vi is always vim
alias vim='vim -p'      # always use -p (open multiple files in tabs instead of same buffer)
alias gvim='gvim -p'    # dito for gvim
alias m='make'          # short for make
alias g='git'           # short for git
alias gka='gitk --all &'  # short for gitk --all
alias o=open            # short for open

# grep: use color
## edit 16.6.2012: it's a bad idea to include -n (numbers) 
##                 because that setting is not auto (matically deactivated when used in pipes) and that confuses scripts.
alias grep='grep --color=auto' 2>/dev/null
alias egrep='egrep --color=auto' 2>/dev/null
alias fgrep='fgrep --color=auto' 2>/dev/null

# ls and friends: use color
alias ls="ls --color=auto"
alias ll="ls -l --color=auto"
alias la="ls -la --color=auto"

# shorthands for multiple parent directories
alias cd..="cd .."
alias cd...="cd ../.."
alias cd....="cd ../../.."
alias cd.....="cd ../../../.."
alias cd......="cd ../../../../.."

# create directory and directly enter it
function mkcd () { 
    mkdir -p "$@" && eval cd "\"\$$#\""
}

# highlight words in output.
# use: cat /etc/passwd | hl root user
# from: http://chneukirchen.org/blog/archive/2013/07/summer-of-scripts-hl.html 
# ported to bash by me using xargs
#   zsh's -e${^*} expands $*="a b c" to -ea -eb -ec
function hl () { 
    if [[ $1 = '-i' ]]; then
        ARGS='--ignore-case'
        shift
    fi
    egrep $ARGS --color=always -e '' $(echo $* | xargs -n1 printf "-e%s "); 
}

# pdfgrep: grep in PDF files (current dir, recursively)
# http://stackoverflow.com/a/4643518
function pdfgrep () {
    find . -name '*.pdf' -exec sh -c 'pdftotext "{}" - | grep --with-filename --label="{}" --color=always '"'$@'" \; 2> /dev/null
}

# grep output of ps (without grep itself)
function psgrep ()
{
    ps aux | grep -v 'grep' | grep "$1" 
}

# don't remember, why this `which` is better than the original one...
if alias which >/dev/null 2>/dev/null; then
    unalias which
fi
which ()
{
    (alias; declare -f) | /usr/bin/which --tty-only --read-alias --read-functions --show-tilde --show-dot $@
}
export -f which

# get PIDs of 1st parameter and kill (SIGTERM) them
# TODO: where is the difference to killall?
function psterm ()
{
    [ ${#} -eq 0 ] && echo "usage: $FUNCNAME STRING" && return 0
    local pid
    pid=$(ps ax | grep "$1" | grep -v grep | awk '{ print $1 }')
    echo -e "terminating '$1' / process(es):\n$pid"
    kill -SIGTERM $pid
}

#
# set prompt
#
COLOR=1
if [[ $COLOR -gt 0 ]]; then
    PROMPT_GREEN='\[\033[01;32m\]'
    PROMPT_BLUE='\[\033[01;34m\]'
    PROMPT_YELLOW='\[\033[01;33m\]'
    PROMPT_RESET='\[\033[00m\]'
else
    PROMPT_GREEN=''
    PROMPT_BLUE=''
    PROMPT_YELLOW=''
    PROMPT_RESET=''
fi

if [ x"$WINDOW" != x ]; then
    # whithin a screen session
    SCREEN=$PROMPT_YELLOW" (screen: $WINDOW) "
else
    # not a screen session
    SCREEN=''
fi

#export PS1="\u@\h:\w$SCREEN\$ "

if type __git_ps1 >/dev/null 2>&1; then
    # from: http://www.bramschoenmakers.nl/en/node/624
    # (requires bash_completion (Git bash completion scripts)
    export PS1=$PROMPT_GREEN'\u@\h'$PROMPT_BLUE' \w'${SCREEN}$PROMPT_YELLOW'$(__git_ps1)'$PROMPT_BLUE' \$ '$PROMPT_RESET
else
    #export PS1="\u@\h:\w$SCREEN\$ "
    export PS1=$PROMPT_GREEN'\u@\h'$PROMPT_BLUE' \w'${SCREEN}$PROMPT_BLUE' \$ '$PROMPT_RESET
fi

if [[ -e /usr/local/packages/pkgtools-2.1/bin/usepkg ]]; then
    # usepkg (/usr/local/packages)
    function usepkg () { eval `/usr/local/packages/pkgtools-2.1/bin/usepkg  $*`; }

    if [[ -e /usr/local/packages/texlive-current ]]; then
        # additional LaTeX files installed locally
        #export TEXINPUTS=/home/wassen/.tex:
        #export INDEXSTYLE=/home/wassen/.tex:
        usepkg texlive-current
    fi
fi

#
# settings only for LfBS account (domain of hostname is lfbs)
#
if [ "$(/bin/hostname -f | cut -d. -f2-)" == lfbs.rwth-aachen.de ]; then

    #
    # settings only for poodoo (my own desktop)
    #
    if [ x`hostname` == xpoodoo ]; then
        # simple cd to v03 (looks up the block* directiries within checkout/BSPR)
        export CDPATH=:~/checkout/BSPR/block1:~/checkout/BSPR/block2:~/checkout/BSPR/block3:~/checkout/BSPR/block4
    fi


    # activate for NMPI:
    #export PATH=/work/wassen/nmpi-1.2/bin:$PATH

    # activate for Open MPI:
    #usepkg -q -l openmpi-1.2.1_udapl_fixed

    #usepkg -q -l totalview-8.3.0-0_x32

    #usepkg -q inkscape                     # not needed, it is installed on most machines
    #export MANPATH=/usr/share/man:$MANPATH


    # for AVR programmer
    export PROGRAMMER_PORT=usb
    export PROGRAMMER=avrispmkII

    #if hostname|grep pd ; then
    #export LD_LIBRARY_PATH=~/sci_collectives/trunk/src/lib
    #       export LD_PRELOAD=/opt/dolphin/active/lib/libksupersockets.so
    #fi

    # this was included from autopackage... 
    # TODO: evaluate, if this is still needed. (it is installed in my LfBS account)
    [[ -f "/home/wassen/.config/autopackage/paths-bash" ]] && . "/home/wassen/.config/autopackage/paths-bash"

    #unset GNOME_KEYRING_CONTROL
    #unset GNOME_KEYRING_PID

fi

# there is room for local extensions that shall not be synchronized between computers
if [ -e ~/.bash_profile_additional ]; then
    . ~/.bash_profile_additional
fi



