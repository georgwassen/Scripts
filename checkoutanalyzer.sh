#!/bin/bash
#===============================================================================
#
#          FILE:  checkoutanalyzer.sh
# 
#         USAGE:  ./checkoutanalyzer.sh 
# 
#   DESCRIPTION:  analyze all checked-out repositories
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Georg Wassen (georg.wassen@googlemail.com), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  01.01.2014 18:22:08 CET
#      REVISION:  ---
#===============================================================================

DIR=~/checkout

COLRED='\033[1;31m'
#COLWHITE='\033[1;37m'
COLBLUE='\033[1;34m'
COLGREEN='\033[1;32m'
COLYELLOW='\033[1;33m'
COLRESET='\033[0m'

cd $DIR
for D in *; do
    if [[ -d $D ]]; then
        pushd $D > /dev/null

        if [[ -d .git ]]; then
            # Git

            STR=$(echo -e "${COLYELLOW}Git${COLRESET} ")
            STR=$STR"$(git -c color.status=always status -sb | tr '\n' ' ' | tr -d '#' )"
        elif [[ -d .svn ]]; then
            # Subversion

            HEAD=$(LANG=C svn info -rHEAD | sed -n 's/^Revision: \([0-9]\+\)$/\1/p')
            V=$(svnversion 2>&1)
            if [[ $V =~ ^svn: ]]; then
                V=$(echo -e "${COLWHITE}Error: ${V}${COLRESET} ")
            elif [[ $V =~ M ]]; then
                V=$(echo -e "${COLRED}${V}${COLRESET} ")
            elif [[ $V =~ : ]]; then
                V=$(echo -e "${COLGREEN}${V}${COLRESET} ")
            fi
            V="[${HEAD}] $V"

            STR=$(echo -e "${COLBLUE}Svn${COLRESET} ")
            STR="$STR$V"
        else
            # unknown
            STR=$(echo -e "${COLRED}unknown${COLRESET} ")
        fi

        printf "%-20s : %s\n" "$D" "$STR"


        popd > /dev/null
    fi
done
