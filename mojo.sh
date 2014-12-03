#!/bin/bash
# Author: Morgan Reynolds

###########
# GLOBALS #
###########
VERSION="14.12.03-1543"

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
    echo "-a <p/e> <dir name>   add project or external"
    echo "-c <command>          do shell command"
    echo "-h                    help"
    echo "-i                    mojo initialize"
    echo "-l                    list projects and externals"
    echo "-r <dir name>         remove project/external from mojo"
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
        done < $DIR/.mojo/projects
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
        done < $DIR/.mojo/externals
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
        done < $DIR/.mojo/projects
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
        done < $DIR/.mojo/externals
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
        done < $DIR/.mojo/projects
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
        done < $DIR/.mojo/externals
    fi
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
        done < $DIR/.mojo/projects
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
        done < $DIR/.mojo/externals
    fi

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
    echo $2 >> $DIR/.mojo/$FILE
    echo "$PASS Added '$2' to $FILE."
    
    # Cleanup
    sort $DIR/.mojo/projects -o $DIR/.mojo/projects
    sort $DIR/.mojo/externals -o $DIR/.mojo/externals
    
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

    rm $DIR/.mojo/projects
    rm $DIR/.mojo/externals
    mv $DIR/.mojo/projects-tmp $DIR/.mojo/projects
    mv $DIR/.mojo/externals-tmp $DIR/.mojo/externals
    echo "$PASS $1 removed from mojo."

}

#################
# CASES IN MAIN #
#################
# Extracted for use with older versions of bash that don't support fallthrough

_commit() {
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
}

_diff() {
    doCommandIfChanges "git status; git diff"
}

_history() {
    touch .mojo/history
    if [ $2 ]; then
        sed -n -e "/$2/,/====/ p" .mojo/history
    else
        less .mojo/history
    fi
}

_push() {
    echo "$INFO Projects to be pushed:"
    showPending
    echo
    
    touch $DIR/.mojo/history-tmp
    date >> $DIR/.mojo/history-tmp
    echo "[ Push ]" >> $DIR/.mojo/history-tmp
    doPush
    
    cd $DIR
    echo "==========" >> $DIR/.mojo/history-tmp
    echo "" >> $DIR/.mojo/history-tmp
    cat $DIR/.mojo/history >> $DIR/.mojo/history-tmp
    cat $DIR/.mojo/history-tmp > $DIR/.mojo/history
    rm $DIR/.mojo/history-tmp
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
                echo "Usage: mojo -a {p[roject] / e[xternal] } [directory]"
            fi
            exit 1
            ;;
        c) 
            mojoCheck
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
    mojoCheck
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
