#!/bin/bash
#===============================================================================
#
#          FILE:  bibgrep_full.sh
# 
#         USAGE:  ./bibgrep_full.sh 
# 
#   DESCRIPTION:  version with full-text search (but display bib key)
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Georg Wassen (georg.wassen@googlemail.com), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  11.12.2013 12:15:37 CET
#      REVISION:  ---
#===============================================================================

SEARCHTERM=Corbet

for FILE in *.bib; do
    POS=0
    while read LINE; do
        POS=$(( POS + 1 ))
        if [[ $LINE =~ ^@[^{]+\{([^,]+),$ ]]; then
            CURRENT_KEY=${BASH_REMATCH[1]}
            CURRENT_POS=$POS
        fi
        if [[ $LINE =~ $SEARCHTERM ]]; then
            echo $FILE:$CURRENT_POS:$CURRENT_KEY
        fi

    done < $FILE | sort -t: -k3 -u

done


