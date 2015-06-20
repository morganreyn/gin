#!/bin/bash
# Author: Morgan Reynolds

###########
# GLOBALS #
###########
VERSION="14.12.18-1415"

DIR=$(pwd)
EXT=$(pwd)
COMMIT="git commit -a"

##############
# TEXT COLOR #
##############

txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgre=${txtbld}$(tput setaf 2) #  green
bldyel=${txtbld}$(tput setaf 3) #  yellow
bldblu=${txtbld}$(tput setaf 4) #  blue
bldvio=${txtbld}$(tput setaf 5) #  violet
bldlbl=${txtbld}$(tput setaf 6) #  light blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset

INFO=${bldblu}INFO:${txtrst}
PASS=${bldgre}SUCCESS:${txtrst}
FAIL=${bldred}FAIL:${txtrst}
WARN=${bldred}WARNING:${txtrst}
STRT=${bldyel}"===---------- Projects ----------==="${txtrst}
SEPR=${bldyel}"===---------- Externals ----------==="${txtrst}

TITLE=${txtbld}$(tput setaf 4)
TITLE_DIRTY=${txtbld}$(tput setaf 1)

#############
# FUNCTIONS #
#############

ginCheck() {
    if [ ! -d ".gin" ]; then
        echo "$INFO This is not a gin directory."
        echo "$INFO Use 'gin -i' to initialize a gin project"
        exit 1
    fi
}

directoryCheck() {
    if [ ! -d "$1/$2" ]; then
        echo "$FAIL Directory $1/$2 not found."
        exit 1
    fi
}

config() {
    if [ -d ".gin" ]; then
        IFS="="
        while read -r name value
        do
            case "${name}" in
                DIR) DIR=$value ;;
                EXT) EXT=$value ;;
                COMMIT) COMMIT=$value ;;
            esac
        done < .gin/config
    fi
}

showConfigs() {
    ginCheck
    cat $DIR/.gin/config
}

help() {
    echo "-a <p/e> <dir name>   add project or external"
    echo "-c <command>          do shell command"
    echo "-h                    help"
    echo "-i                    gin initialize"
    echo "-l                    list projects and externals"
    echo "-r <dir name>         remove project/external from gin"
    echo "-s                    show configuration values"
    echo "-v                    show version"
    echo
    echo "c, commit [message]   commit all changes"
    echo "d, diff               diff all edited files"
    echo "h, history [term]     show commit history (optional search for 'term')"
    echo "p, push               push changes to server"
    echo "master                switch all to 'master' branch"
    echo "reset                 reset all files back to HEAD"
    echo "s, status             show git status when changes have occured"
    echo "S, Status             show git status of all items"
    echo "su, stash-update      stash changes, update, pop stash"
    echo "u, update             rebase all projects and externals"
    echo "U, Update             update and fetch all branch updates"
    echo "x <term> <command>    execute command in projects/externals whose names include 'term'"
    exit 1
}

init() {
    if [ -d ".gin" ]; then
        echo "gin directory reinitializing...."
    else
        echo "Initializing gin directory..."
        mkdir .gin
    fi
    touch .gin/projects
    touch .gin/externals
    touch .gin/config
    touch .gin/history
    echo "DIR=$DIR" > .gin/config
    echo "EXT=$DIR" >> .gin/config
    echo "COMMIT=\"git commit -a\"" >> .gin/config
    exit 1
}

doCommand() {
    if [ $RUNPROJ == 1 ]; then
        echo "${STRT}"
        echo
        while read line
        do
            cd $DIR/$line
            if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
                echo "${TITLE_DIRTY}======[ $line -- push pending ${txtrst}"
            else
                echo "${TITLE}======[ $line ${txtrst}"
            fi

            eval $@
            echo
        done < $DIR/.gin/projects
    fi
    if [ $RUNEXT == 1 ]; then
        echo "${SEPR}"
        echo
        while read line
        do
            cd $EXT/$line
            if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
                echo "${TITLE_DIRTY}------[ $line -- push pending ${txtrst}"
            else
                echo "${TITLE}------[ $line ${txtrst}"
            fi
       	    eval $@
            echo
        done < $DIR/.gin/externals
    fi
}

doCommandIfChanges() {
    if [ $RUNPROJ == 1 ]; then
        echo "${STRT}"
        echo
        while read line
        do
	    cd $DIR/$line
            if [[ -z $(git status | grep -i 'nothing to commit') ]]; then
                echo "${TITLE}======[ $line ${txtrst}"
                eval $@
                echo
            fi
        done < $DIR/.gin/projects
    fi
    if [ $RUNEXT == 1 ]; then
        echo "${SEPR}"
        echo
        while read line
        do
            cd $EXT/$line
            if [[ -z $(git status | grep -i 'nothing to commit') ]]; then
                echo "${TITLE}------[ $line ${txtrst}"
                eval $@
                echo
            fi
        done < $DIR/.gin/externals
    fi
}

executeSelective() {
    if [ $RUNPROJ == 1 ]; then
        echo "${STRT}"
        echo
        while read line
        do
            if [[ $line == *$1* ]]; then
                echo "${TITLE}======[ $line ${txtrst}"
                cd $DIR/$line
                eval $2
                echo
            fi
        done < $DIR/.gin/projects
    fi
    if [ $RUNEXT == 1 ]; then
        echo "${SEPR}"
        echo
        while read line
        do
            if [[ $line == *$1* ]]; then
                echo "${TITLE}------[ $line ${txtrst}"
                cd $EXT/$line
                eval $2
                echo
            fi
        done < $DIR/.gin/externals
    fi
}

showPending() {
    while read line
    do
        cd $DIR/$line
        if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
            echo " $line"
        fi
    done < $DIR/.gin/projects

    while read line
    do
        cd $EXT/$line
        if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
            echo " $line"
        fi
    done < $DIR/.gin/externals
}

doPush() {
    if [ $RUNPROJ == 1 ]; then
        while read line
        do
            cd $DIR/$line
            if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
                STASH=0
                if [[ -z $(git status | grep -i 'nothing to commit') ]]; then
                    STASH=1
                    echo "Stashing changes for $line"
                    git stash
                fi
                git svn dcommit
                if [ $STASH == 1 ]; then
                    echo "Unstashing changes for $line"
                    git stash pop
                fi
            fi
        done < $DIR/.gin/projects
    fi
    if [ $RUNEXT == 1 ]; then
        while read line
        do
            cd $EXT/$line
            if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
                STASH=0
                if [[ -z $(git status | grep -i 'nothing to commit') ]]; then
                    STASH=1
                    echo "Stashing changes for $line"
                    git stash
                fi
                git svn dcommit
                if [[ $STASH == 1 ]]; then
                    echo "Unstashing changes for $line"
                    git stash pop
                fi
            fi
        done < $DIR/.gin/externals
    fi

}

list() {
    ginCheck
    echo "Projects:"
    while read line
    do
        echo " $line"
    done < .gin/projects
    echo ""
    echo "Externals:"
    while read line
    do
        echo " $line"
    done < .gin/externals
    echo ""
    exit 1
}

add() {
    ginCheck
    FILE=""
    case "$1" in
        p)
            directoryCheck $DIR $2
            FILE="projects"
            ;;
        project)
            directoryCheck $DIR $2
            FILE="projects"
            ;;
        projects)
            directoryCheck $DIR $2
            FILE="projects"
            ;;

        e)
            directoryCheck $EXT $2
            FILE="externals"
            ;;
        external)
            directoryCheck $EXT $2
            FILE="externals"
            ;;
        externals)
            directoryCheck $EXT $2
            FILE="externals"
            ;;
    esac

    checkAdd $2
    echo $2 >> $DIR/.gin/$FILE
    echo "$PASS Added '$2' to $FILE."

    # Cleanup
    sort $DIR/.gin/projects -o $DIR/.gin/projects
    sort $DIR/.gin/externals -o $DIR/.gin/externals

    exit 1
}

checkAdd() {
    PRJS="|"
    EXTS="|"

    while read line
    do
        PRJS="$PRJS $line |"
    done < $DIR/.gin/projects

    while read line
    do
       	EXTS="$EXTS $line"
    done < $DIR/.gin/externals

    if [[ "$PRJS" =~ "$1" ]]; then
        echo "$FAIL $1 already exists in projects."
        exit 1
    fi

    if [[ "$EXTS" =~ "$1" ]]; then
        echo "$FAIL $1 already exists in externals."
        exit 1
    fi
}

remove() {
    ginCheck
    touch $DIR/.gin/projects-tmp
    touch $DIR/.gin/externals-tmp
    while read line
    do
		if [[ "$line" != "$1" ]]; then
		    echo $line >> .gin/projects-tmp
		else
		    echo "$INFO Removing $1 from projects..."
		fi
    done < $DIR/.gin/projects

    while read line
    do
        if [[ "$line" != "$1" ]]; then
		    echo $line >> .gin/externals-tmp
		else
		    echo "$INFO Removing $1 from externals..."
		fi
    done < $DIR/.gin/externals

    rm $DIR/.gin/projects
    rm $DIR/.gin/externals
    mv $DIR/.gin/projects-tmp $DIR/.gin/projects
    mv $DIR/.gin/externals-tmp $DIR/.gin/externals
    echo "$PASS $1 removed from gin."

}

#################
# CASES IN MAIN #
#################
# Extracted for use with older versions of bash that don't support fallthrough... I'm looking at you Apple.

_commit() {
    touch .gin/history-tmp
	date >> .gin/history-tmp
	echo "[ Commit ] $2" >> .gin/history-tmp
    doCommandIfChanges "git add --all; eval $COMMIT; pwd >> $DIR/.gin/history-tmp"
    cd $DIR
    echo "==========" >> .gin/history-tmp
    echo "" >> .gin/history-tmp
    cat .gin/history >> .gin/history-tmp
    cat .gin/history-tmp > .gin/history
    rm .gin/history-tmp
}

_diff() {
    doCommandIfChanges "git status; git diff"
}

_history() {
    touch .gin/history
    if [ $2 ]; then
        sed -n -e "/$2/,/====/ p" .gin/history
    else
        less .gin/history
    fi
}

_push() {
    echo "$INFO Projects to be pushed:"
    showPending
    echo

    echo -n "Push will commence in: ";

    echo -n "3"
    sleep 0.33
    echo -n "."
    sleep 0.33
    echo -n "."
    sleep 0.33
    echo -n "."
    sleep 0.33

    echo -n "2"
    sleep 0.33
    echo -n "."
    sleep 0.33
    echo -n "."
    sleep 0.33
    echo -n "."
    sleep 0.33

    echo -n "1"
    sleep 0.33
    echo -n "."
    sleep 0.33
    echo -n "."
    sleep 0.33
    echo -n "."
    sleep 0.33

    echo

    touch $DIR/.gin/history-tmp
    date >> $DIR/.gin/history-tmp
    echo "[ Push ]" >> $DIR/.gin/history-tmp
    doPush

    cd $DIR
    echo "==========" >> $DIR/.gin/history-tmp
    echo "" >> $DIR/.gin/history-tmp
    cat $DIR/.gin/history >> $DIR/.gin/history-tmp
    cat $DIR/.gin/history-tmp > $DIR/.gin/history
    rm $DIR/.gin/history-tmp
}

_status() {
    doCommandIfChanges "git status"
    echo "$INFO Pending Push:"
    showPending
    echo ""
}

########
# MAIN #
########
config
RUNPROJ=1
RUNEXT=1
while getopts "a:c:e:hilp:r:sv" o; do
    case "${o}" in
        a)
            if [[ $3 ]]; then
                add ${OPTARG} $3
            else
                echo "Usage: gin -a {p[roject] / e[xternal] } [directory]"
            fi
            exit 1
            ;;
        c)
            ginCheck
            doCommand "${OPTARG}"
            exit 1
            ;;
#         e)
#             RUNPROJ=0
#             ;;
        h)
            help
            exit 1
            ;;
        i)
            init
            exit 1
            ;;
        l)
            list
            exit 1
            ;;
#         p)
#             RUNEXT=0
#             ;;
        r)
            remove ${OPTARG}
            exit 1
            ;;
        s) showConfigs
            exit 1
            ;;
        v)
            echo $VERSION
            exit 1
            ;;
    esac
done

if [ $1 ]; then
    ginCheck
    date
    case $1 in
        c) _commit $@ ;;
        commit) _commit $@ ;;

        d) _diff $@ ;;
        diff) _diff $@ ;;

        h) _history $@ ;;
        history) _history $@ ;;

        p) _push $@ ;;
        push) _push $@ ;;

        master)
            doCommand "git checkout master"
            ;;

        reset)
            doCommand "git reset --hard"
            ;;

        s) _status $@ ;;
        status) _status $@ ;;

        S) doCommand "git status" ;;
        Status) doCommand "git status" ;;

        su) doCommand "git stash; git svn rebase; git stash pop" ;;
        stash-update) doCommand "git stash; git svn rebase; git stash pop" ;;

        u) doCommand "git svn rebase" ;;
        update) doCommand "git svn rebase" ;;

        U) doCommand "git svn rebase; git svn fetch" ;;
        Update) doCommand "git svn rebase; git svn fetch" ;;

        x) executeSelective $2 $3 ;;

        *) help ;;
    esac
    exit 1
fi

help
