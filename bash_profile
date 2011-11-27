# vim: set ft=sh :
#
# symbolic link ~/scripts -> ~/checkout/privat/config/home/scripts
#
# .bashrc : source .bash_profile
# .bash_profile : source ~/scripts/bash_profile
#


# remap CAPS-LOCK key to Escape
if [ _$TERM == _xterm -a _$DISPLAY != _ ]; then
    setxkbmap -model ms
    xmodmap ~/scripts/xmodmap-esc
fi
# remap CAPS-LOCK key to Escape
#if [ _$TERM == _xterm -a _$DISPLAY != _ ]; then
#    xmodmap ~/.xmodmap-esc
#fi

export PATH=$PATH:~/bin:~/bin/dmd/bin:~/scripts

set -o vi
export EDITOR=vi

export HISTCONTROL=ignorespace:ignoredups
export HISTIGNORE='svn ci*:ls'

ulimit -c 400000        # max core dump size
ulimit -v 2097152       # limit max. virtual Memory per process

alias v='gvim'
alias vi='vim'
alias vim='vim -p'
alias gvim='gvim -p'

alias grep='grep -n --color=auto' 2>/dev/null
alias egrep='egrep -n --color=auto' 2>/dev/null
alias fgrep='fgrep -n --color=auto' 2>/dev/null

alias ls="ls --color=auto"
alias ll="ls -l --color=auto"
alias la="ls -la --color=auto"

alias cd..="cd .."
alias cd...="cd ../.."
alias cd....="cd ../../.."
alias cd.....="cd ../../../.."
alias cd......="cd ../../../../.."

function mkcd () { 
    mkdir -p "$@" && eval cd "\"\$$#\""
}

function psgrep ()
{
    ps aux | grep "$1" | grep -v 'grep'
}

function psterm ()
{
    [ ${#} -eq 0 ] && echo "usage: $FUNCNAME STRING" && return 0
    local pid
    pid=$(ps ax | grep "$1" | grep -v grep | awk '{ print $1 }')
    echo -e "terminating '$1' / process(es):\n$pid"
    kill -SIGTERM $pid
}

if [ x"$WINDOW" != x ]; then
    SCREEN=" (screen: $WINDOW) "
else
    SCREEN=""
fi
export PS1="\u@\h:\w$SCREEN\$ "

if [ "$(/bin/hostname --domain 2>/dev/null)" == lfbs.rwth-aachen.de ]; then

    if [ x`hostname` == xpoodoo ]; then
        export CDPATH=:~/checkout/BSPR/block1:~/checkout/BSPR/block2:~/checkout/BSPR/block3:~/checkout/BSPR/block4
    fi

    function usepkg () { eval `/usr/local/packages/pkgtools-2.1/bin/usepkg  $*`; }

    # activate for NMPI:
    #export PATH=/work/wassen/nmpi-1.2/bin:$PATH

    # activate for Open MPI:
    #usepkg -q -l openmpi-1.2.1_udapl_fixed

    #usepkg -q inkscape
    #usepkg -q -l totalview-8.3.0-0_x32
    #export MANPATH=/usr/share/man:$MANPATH

    # additional LaTeX files installed locally
    #export TEXINPUTS=/home/wassen/.tex:
    #export INDEXSTYLE=/home/wassen/.tex:
    usepkg texlive-current

    # for AVR programmer
    export PROGRAMMER_PORT=usb
    export PROGRAMMER=avrispmkII

    #if hostname|grep pd ; then

    #export LD_LIBRARY_PATH=~/sci_collectives/trunk/src/lib
    #       export LD_PRELOAD=/opt/dolphin/active/lib/libksupersockets.so
    #fi

    [[ -f "/home/wassen/.config/autopackage/paths-bash" ]] && . "/home/wassen/.config/autopackage/paths-bash"

fi




