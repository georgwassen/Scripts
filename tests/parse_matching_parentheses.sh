#!/bin/bash
#===============================================================================
#
#          FILE:  test.sh
# 
#         USAGE:  ./test.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:   (), 
#       COMPANY:  
#       VERSION:  1.0
#       CREATED:  14.06.2013 10:25:49 CEST
#      REVISION:  ---
#===============================================================================


function mytest() {
PARAMS=$1
echo "Start: '$PARAMS'"
#while [[ $PARAMS =~ (.*)\$\((.*)\)(.*) ]]; do
#    echo "  found: [0]='${BASH_REMATCH[0]}' [1]='${BASH_REMATCH[1]}' [2]='${BASH_REMATCH[2]}' [3]='${BASH_REMATCH[3]}'"
#    QUERY=${BASH_REMATCH[2]}
#    echo "    query: $QUERY"
#    if [[ $QUERY = 'EF' ]]; then
#        RESULT='$(xy)'
#    else
#        RESULT=zz
#    fi
#    echo "      result: $RESULT"
#    PARAMS=${BASH_REMATCH[1]}${RESULT}${BASH_REMATCH[3]}
#    echo "        new: '$PARAMS'"
#done
while /bin/true; do
    # current length of string
    LEN=${#PARAMS}
    echo "  LEN='$LEN'"
    # substring up to first '$(' 
    PREFIX=${PARAMS%%\$(*}
    echo "  PREFIX='$PREFIX'"
    # pos of '$(' is length of substring
    POS=${#PREFIX}
    # increment by 2 for first position of query
    POS=$(( POS + 2 ))
    echo "  POS='$POS'"
    if [[ $POS -ge $LEN ]]; then
        # break, if that's longer than string: no more '$('
        break
    fi
    # find ending ')'
    END=$((POS+1))
    # count nested parentheses
    PAREN=0
    while [[ $END -lt $LEN ]]; do
        if [[ ${PARAMS:$END:1} = '(' ]]; then
            # found opening parenthesis: increment
            PAREN=$(( PAREN + 1 ))
        elif [[ ${PARAMS:$END:1} = ')' ]]; then
            # found closing parenthesis
            if [[ $PAREN -gt 0 ]]; then
                # if still nested: decrement
                PAREN=$(( PAREN - 1 ))
            else
                # else: found matching closing parenthesis
                break
            fi
        fi
        # advance to next character
        END=$(( END + 1 ))
    done
    # previous loop was left by closing parenthesis or end-of-string
    echo "  END='$END'"
    # query is text between POS and END-1
    QUERY=${PARAMS:$POS:$(( END-POS ))}
    echo "  QUERY='$QUERY'"
    # execute query...
    ANSWER=xx
    echo "  ANSWER='$ANSWER'"
    # replace '$(' .. ')' with answer to query
    PARAMS=$PREFIX$ANSWER${PARAMS:$(( END+1))}
    echo "  new PARAMS='$PARAMS'"
done

echo "End:   '$PARAMS'"
echo 
}


mytest 'ABCD'
mytest 'AB$(CD)EF'
mytest 'AB $(CD) EF'
mytest 'AB $(CD)$(EF)GH'
mytest 'AB $(C(x)D) EF'
mytest 'AB $(C(x)D) EF (us)'
mytest 'AB $(C$(x)D) EF (us)'
