#!/bin/bash
# Author: Morgan Reynolds

###########
# GLOBALS #
###########
VERSION="0.1.4"

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
PASS=${bldgre}PASS:${txtrst}
WARN=${bldred}WARNING:${txtrst}
SEPR=${bldyel}"===---------- Externals ----------==="${txtrst}

TITLE=${txtbld}$(tput setaf 4)
TITLE_DIRTY=${txtbld}$(tput setaf 1)

#############
# FUNCTIONS #
#############

mojoCheck() {
    if [ ! -d ".mojo" ]; then
        echo "This is not a mojo directory."
        echo "Use 'mojo -i' to initialize a mojo project"
        exit 1
    fi
}

config() {
    if [ -d ".mojo" ]; then
        IFS="="
        while read -r name value
        do
             case "${name}" in
                DIR) DIR=$value ;;
                EXT) EXT=$value ;;
                COMMIT) COMMIT=$value ;;
            esac
        done < .mojo/config
    fi
}

showConfigs() {
    mojoCheck
    cat $DIR/.mojo/config
}

help() {
    echo "-c <command>   do shell command"
    echo "-h             help"
    echo "-i             mojo initialize"
    echo "-l             list projects and externals"
    echo "-p <name>      add project"
    echo "-s             show configuration values"
    echo "-v             show version"
    echo "-x <name>      add external"
    echo
    echo "c, commit      commit all changes"
    echo "d, diff        diff all edited files"
    echo "p, push        push changes to server"
    echo "reset          reset all files back to HEAD"
    echo "u, update      rebase all projects and externals"
    exit 1
}

init() {
    if [ -d ".mojo" ]; then
        echo "mojo directory reinitializing...."
    else
        echo "Initializing mojo directory..."
        mkdir .mojo
    fi
    touch .mojo/projects
    touch .mojo/externals
    touch .mojo/config
    touch .mojo/push-projects
    touch .mojo/push-externals
    echo "DIR=$DIR" > .mojo/config
    echo "EXT=$DIR" >> .mojo/config
    echo "COMMIT=\"gitg -c\"" >> .mojo/config
    exit 1
}

doCommand() {
    PRJS="|"
    EXTS="|"

    while read line
    do
        PRJS="$PRJS $line |"
    done < $DIR/.mojo/push-projects

    while read line
    do
        EXTS="$EXTS $line"
    done < $DIR/.mojo/push-externals


    while read line
    do
        if [[ "$PRJS" =~ "$line" ]]; then
            echo "${TITLE_DIRTY}====================================="
            echo "| $line -- push pending"
            echo "=====================================${txtrst}"
        else
            echo "${TITLE}====================================="
            echo "| $line"
            echo "=====================================${txtrst}"
        fi
        cd $DIR/$line
        eval $@
        echo
    done < $DIR/.mojo/projects
    echo "${SEPR}"
    echo
    while read line
    do
        if [[ "$EXTS" =~ "$line" ]]; then
            echo "${TITLE_DIRTY}====================================="
            echo "| $line -- push pending"
            echo "=====================================${txtrst}"
        else
            echo "${TITLE}====================================="
            echo "| $line"
            echo "=====================================${txtrst}"
        fi
       	cd $EXT/$line
       	eval $@
        echo
    done < $DIR/.mojo/externals
}

doCommandIfChanges() {
    while read line
    do
	cd $DIR/$line
        if [[ -z $(git status | grep -i 'nothing to commit') ]]; then
            echo "${TITLE}====================================="
            echo "| $line"
            echo "=====================================${txtrst}"
            eval $@
            if [[ ! -z $(echo "$@" | grep $COMMIT) ]]; then
                addPush projects $line
            fi
            echo
        fi
    done < $DIR/.mojo/projects
    echo "${SEPR}"
    echo
    while read line
    do
        cd $EXT/$line
        if [[ -z $(git status | grep -i 'nothing to commit') ]]; then
            echo "${TITLE}====================================="
            echo "| $line"
            echo "=====================================${txtrst}"
            eval $@
            if [[ ! -z $(echo "$@" | grep $COMMIT) ]]; then
                addPush externals $line
            fi
            echo
        fi
    done < $DIR/.mojo/externals
}

addPush() {
    PRJS="|"
    EXTS="|"

    while read line
    do
        PRJS="$PRJS $line |"
    done < $DIR/.mojo/push-projects

    while read line
    do
       	EXTS="$EXTS $line"
    done < $DIR/.mojo/push-externals

    if [[ "$1" == "projects" ]]; then
        if [[ ! "$PRJS" =~ "$2" ]]; then
            echo $2 >> $DIR/.mojo/push-projects
        fi
    fi
    if [[ "$1" == "externals" ]]; then
        if [[ ! "$EXTS" =~ "$2" ]]; then
            echo $2 >> $DIR/.mojo/push-externals
        fi
    fi
}

doPush() {
    while read line
    do
        STASH=0
        cd $DIR/$line
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
    done < $DIR/.mojo/projects

    while read line
    do
      	STASH=0
        cd $EXT/$line
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
    done < $DIR/.mojo/externals

    rm $DIR/.mojo/push-projects
    rm $DIR/.mojo/push-externals
    touch $DIR/.mojo/push-projects
    touch $DIR/.mojo/push-externals

}

list() {
    mojoCheck
    echo "Projects:"
    while read line
    do
        echo " $line"
    done < .mojo/projects
    echo ""
    echo "Externals:"
    while read line
    do
        echo " $line"
    done < .mojo/externals
    echo ""
    exit 1
}

add() {
    mojoCheck
    echo "Adding '$1' to $2..."
    echo $1 >> .mojo/$2
    exit 1
}

########
# MAIN #
########
config
while getopts "c:hilp:svx:z:" o; do
    case "${o}" in
        c) doCommand "${OPTARG}" ;;
        h) help ;;
        i) init ;;
        l) list ;;
        p) add ${OPTARG} projects ;;
        s) showConfigs ;;
        v) echo $VERSION ;;
        x) add ${OPTARG} externals ;;
        *) help ;;
    esac
    exit 1;
done

if [ $1 ]; then
    mojoCheck
    case $1 in
        #TODO: b)
        #TODO: build)
        c) ;&
        commit)
            doCommandIfChanges "git add --all; eval $COMMIT"
            ;;
        d) ;&
        diff)
            doCommandIfChanges "git status; git diff"
            echo "done."
            ;;
        p) ;&
        push)
            echo    "$WARN This will push all local commits to the server."
            read -p "$WARN Are you really ready to push? [Y/n] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Y]$ ]]; then
                doPush
            else
                echo "$INFO Push cancelled."
            fi

           ;;
        reset)
            echo    "$WARN The command 'git reset --hard' cannot be undone."
            read -p "$WARN Are you sure? [Y/n] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Y]$ ]]; then
                doCommand "git reset --hard"
            else
                echo "$INFO Reset cancelled."
            fi
            ;;
        s) ;&
        status)
            doCommand "git status"
            ;;
        u) ;&
        update)
            doCommand "git svn rebase"
            ;;
        *)
            help ;;
    esac
    exit 1
fi

help
