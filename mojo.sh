#!/bin/bash
# Author: Morgan Reynolds

###########
# GLOBALS #
###########
VERSION="14.11.04-1306"

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

mojoCheck() {
    if [ ! -d ".mojo" ]; then
        echo "$INFO This is not a mojo directory."
        echo "$INFO Use 'mojo -i' to initialize a mojo project"
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
    echo "-c <command>          do shell command"
    echo "-e <name>             add external"
    echo "-h                    help"
    echo "-i                    mojo initialize"
    echo "-l                    list projects and externals"
    echo "-p <name>             add project"
    echo "-r <name>             remove project/external from mojo"
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
    if [ -d ".mojo" ]; then
        echo "mojo directory reinitializing...."
    else
        echo "Initializing mojo directory..."
        mkdir .mojo
    fi
    touch .mojo/projects
    touch .mojo/externals
    touch .mojo/config
    touch .mojo/history
    echo "DIR=$DIR" > .mojo/config
    echo "EXT=$DIR" >> .mojo/config
    echo "COMMIT=\"git commit -a\"" >> .mojo/config
    exit 1
}

doCommand() {
    
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
    done < $DIR/.mojo/projects
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
    done < $DIR/.mojo/externals
}

doCommandIfChanges() {
    echo "${STRT}"
    echo 
    while read line
    do
	cd $DIR/$line
        if [[ -z $(git status | grep -i 'nothing to commit') ]]; then
            echo "${TITLE}======[ $line ${txtrst}"
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
            echo "${TITLE}------[ $line ${txtrst}"
            eval $@
            if [[ ! -z $(echo "$@" | grep $COMMIT) ]]; then
                addPush externals $line
            fi
            echo
        fi
    done < $DIR/.mojo/externals
}

executeSelective() {
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
    done < $DIR/.mojo/projects
    echo "${SEPR}"
    echo
    while read line
    do
        if [[ $line == *$1* ]]; then
            echo "${TITLE}======[ $line ${txtrst}" 
            cd $EXT/$line         
            eval $2            
            echo
        fi
    done < $DIR/.mojo/externals
}

showPending() {
    while read line
    do
        cd $DIR/$line
        if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
            echo " $line"
        fi
    done < $DIR/.mojo/projects
    
    while read line
    do
        cd $EXT/$line
        if [[ -n $(git log --branches --not --remotes --simplify-by-decoration --decorate --oneline) ]]; then
            echo " $line"
        fi
    done < $DIR/.mojo/externals
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
    case "$2" in
        projects)  directoryCheck $DIR $1 ;;
        externals) directoryCheck $EXT $1 ;;
    esac

    checkAdd $1
    echo $1 >> .mojo/$2
    echo "$PASS Added '$1' to $2."
    exit 1
}

checkAdd() {
    PRJS="|"
    EXTS="|"

    while read line
    do
        PRJS="$PRJS $line |"
    done < $DIR/.mojo/projects

    while read line
    do
       	EXTS="$EXTS $line"
    done < $DIR/.mojo/externals

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
    mojoCheck
    touch $DIR/.mojo/projects-tmp
    touch $DIR/.mojo/externals-tmp
    while read line
    do
		if [[ "$line" != "$1" ]]; then
		    echo $line >> .mojo/projects-tmp
		else
		    echo "$INFO Removing $1 from projects..."
		fi
    done < $DIR/.mojo/projects

    while read line
    do
        if [[ "$line" != "$1" ]]; then
		    echo $line >> .mojo/externals-tmp
		else
		    echo "$INFO Removing $1 from externals..."
		fi
    done < $DIR/.mojo/externals

    rm .mojo/projects
    rm .mojo/externals
    mv .mojo/projects-tmp .mojo/projects
    mv .mojo/externals-tmp .mojo/externals
    echo "$PASS $1 removed from mojo."

}

########
# MAIN #
########
config
while getopts "c:e:hilp:r:sv" o; do
    case "${o}" in
        c) doCommand "${OPTARG}" ;;
        e) add ${OPTARG} externals ;;
        h) help ;;
        i) init ;;
        l) list ;;
        p) add ${OPTARG} projects ;;
        r) remove ${OPTARG} ;;
        s) showConfigs ;;
        v) echo $VERSION ;;
        *) help ;;
    esac
    exit 1;
done
if [ $1 ]; then
    mojoCheck
    date
    case $1 in
        c) ;&
        commit)
            touch .mojo/history-tmp
			date >> .mojo/history-tmp
			echo "[ Commit ] $2" >> .mojo/history-tmp
            doCommandIfChanges "git add --all; eval $COMMIT; pwd >> $DIR/.mojo/history-tmp"
            cd $DIR
            echo "==========" >> .mojo/history-tmp
            echo "" >> .mojo/history-tmp
            cat .mojo/history >> .mojo/history-tmp
            cat .mojo/history-tmp > .mojo/history
            rm .mojo/history-tmp
            ;;
        d) ;&
        diff)
            doCommandIfChanges "git status; git diff"
            echo "done."
            ;;
		h) ;&
		history)
		    touch .mojo/history
			if [ $2 ]; then
			    sed -n -e "/$2/,/====/ p" .mojo/history
			else
			    less .mojo/history
			fi
			;;
        p) ;&
        push)
            echo    "$WARN This will push ALL local commits to the server."
            read -p "$WARN Are you really ready to push? [Y/n] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Y]$ ]]; then
				touch .mojo/history-tmp
				date >> .mojo/history-tmp
				echo "[ Push ]" >> .mojo/history-tmp
				doPush
				cd $DIR
				echo "==========" >> .mojo/history-tmp
				echo "" >> .mojo/history-tmp
				cat .mojo/history >> .mojo/history-tmp
				cat .mojo/history-tmp > .mojo/history
				rm .mojo/history-tmp
            else
                echo "$INFO Push cancelled."
            fi

           ;;
        master)
            doCommand "git checkout master"
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
            doCommandIfChanges "git status"
            echo "Pending Push:"
            showPending
            ;;
        S) ;&
        Status) 
			doCommand "git status"
			;;
		su) ;&
		stash-update)
			doCommand "git stash; git svn rebase; git stash pop"
			;;
        u) ;&
        update)
            doCommand "git svn rebase"
            ;;
        U) ;&
        Update)
            doCommand "git svn rebase; git svn fetch"
            ;;
        x)
            executeSelective $2 $3
            ;;
        *)
            help ;;
    esac
    exit 1
fi

help
