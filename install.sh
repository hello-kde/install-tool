#!/bin/sh

# thanks to the Papirus team for providing the base script
# as part of the arc-kde theme set

set -e

_repo="hello"

# ascii art because everyone loves ascii art

_ascii(){
cat <<- EOF
    ,dPYb,              ,dPYb, ,dPYb,             
    IP'\`Yb              IP'\`Yb IP'\`Yb             
    I8  8I              I8  8I I8  8I             
    I8  8'              I8  8' I8  8'             
    I8 dPgg,    ,ggg,   I8 dP  I8 dP    ,ggggg,   
    I8dP" "8I  i8" "8i  I8dP   I8dP    dP"  "Y8ggg
    I8P    I8  I8, ,8I  I8P    I8P    i8'    ,8I  
    ,d8     I8, \`YbadP' ,d8b,_ ,d8b,_ ,d8,   ,d8'  ,gg,
    88P     \`Y8888P"Y8888P'"Y888P'"Y88P"Y8888P"    \`YP'


    The complete KDE theme.
    https://github.com/n4n0GH/$_repo

    
EOF
}

: "${PREFIX:=/usr}"
: "${TAG:=master}"

# nicer echo defaults

_out() {
    echo -e "\e[32m[?]\e[0m" "$@" >&2
}

_inp() {
    echo -e "   " "$@" >&2
}

_do() {
    echo -e "\e[33m[>]\e[0m" "$@" >&2
}

_err() {
    echo -e "\e[31m[!]" "$@\e[0m" >&2
}

# define program routines

# remove file and parent directory if empty
_del() {
    _do "Removing $1 ..."
    sudo rm -rf "$1"
    sudo rmdir -p "$(dirname "$1")" 2>/dev/null || true
}

# download the latest release and unpack to temp dir
_download() {
    clear
    _ascii
    _do "Getting the latest version from GitHub ..."
    wget -O "$temp_file" \
        "https://github.com/n4n0GH/$_repo/archive/$TAG.tar.gz"
    _do "Unpacking archive ..."
    tar -xzf "$temp_file" -C "$temp_dir"
}

# removes all files installed by hello
_remove() {
    clear
    _ascii
    # TODO: adjust removal process to accomodate hello parts
    _do "Starting removal of hello..."
    _del "$PREFIX/share/aurorae/themes/Arc"
    
}

# start cmake installation, awaits sudo input at one time
_install() {
    clear
    _ascii
    _do "Installing ..."
    cd "$temp_dir/$_repo-$TAG"
    mkdir "build" && cd "build"
    cmake -DCMAKE_INSTALL_PREFIX="$PREFIX" ..
    make
    _do "Your root password is needed to install some parts like the window decoration and application style into the '$PREFIX' directory. If you don't feel comfortable sharing your root password, feel free to open this installation script in any text editor and inspect the source code."
    _out "Do you want to continue?"
    while true; do
        _inp "(\e[1mY\e[0m)es"
        _inp "(\e[1mN\e[0m)o"
        read -n 1 -p  "[$] " _manual
        echo " "
        if [ "$_manual" = "y" ] \
            || [ "$_manual" = "Y" ]; then
            _do "Resuming installation ..."
            break
        elif [ "$_manual" = "n" ] \
            || [ "$_manual" = "N" ]; then
            _postwork
        else
            clear
            _ascii
            _err "I'm sorry, but that is not a valid input."
            _out "Do you want to continue with the installation?"
        fi
    done
    sudo make install
}

# remove unnecessary files and restart kwin and plasma
_postwork() {
    clear
    _ascii
    _do "Clearing cache ..."
    rm -rf "$temp_file" "$temp_dir"
    # the next part will restart kwin and plasma in a way
    # that routes the output you'd usually see cluttering
    # up the terminal to /dev/null and not annoy the user
    _do "Restarting KWin ..."
    kwin_x11 --replace > /dev/null 2>&1 &
    _do "Restarting Plasma ..."
    plasmashell --replace > /dev/null 2>&1 &
    _do "All done, enjoy hello."
    exit
}

# check system for dependencies on OS level, install if needed
_check(){ 
    clear
    _ascii
    _do "Detecting operating system ..."
    if [ -n "$(command -v lsb_release)" ]; then
        _distro=$(lsb_release -s -d | tr -d '="')
    elif [ -f "/etc/os-release" ]; then
        _distro=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="')
    else
        _distro="your system"
    fi
    _supported=("Ubuntu" "Arch" "Fedora" "Manjaro" "openSUSE")
    if [[ ! $_distro =~ $_supported ]]; then
        _err "I'm sorry but the automated dependency check is not supported on $_distro. If you manually installed the depencies you can continue the installation and skip this step."
        _out "Do you want to continue?"
        while true; do
            _inp "(\e[1mY\e[0m)es"
            _inp "(\e[1mN\e[0m)o"
            read -n 1 -p  "[$] " _manual
            echo " "
            if [ "$_manual" = "y" ] \
                || [ "$_manual" = "Y" ]; then
                _do "Resuming installation ..."
                break
            elif [ "$_manual" = "n" ] \
                || [ "$_manual" = "N" ]; then
                _do "Exiting ..."
                exit
            else
                clear
                _ascii
                _err "I'm sorry, but that is not a valid input."
                _out "Do you want to continue with the installation?"
            fi
        done
    else
        # TODO: run OS specific dependecy checks
        _do "Checking dependencies ..."
        # TODO: install dependencies if necessary
        _do "Installing missing dependencies ..."
    fi
}

_testrun(){
    clear
    _ascii
    _err "Please note that hello assumes you solved all build dependencies before running this script. If that is not the case the installation will fail. Please raise an issue at https://github.com/n4n0GH/hello if you need help setting everything up on your operating system."
    _out "Do you want to continue?"
    while true; do
        _inp "(\e[1mY\e[0m)es"
        _inp "(\e[1mN\e[0m)o"
        read -n 1 -p "[$] " _continue
        echo " "
        if [ "$_continue" = "n" ] \
            || [ "$_continue" = "N" ]; then
            _do "Exiting ..."
            exit
        elif [ "$_continue" = "y" ] \
            || [ "$_continue" = "Y" ]; then
            break
        else
            clear
            _ascii
            _err "I'm sorry, but that is not a valid input."
            _out "Do you want to continue with the installation?"
        fi
    done
}

# ask for user input, start processes accordingly
_hello(){
    _out "What do you want to do?"
    _inp "(\e[1mI\e[0m)nstall or update hello"
    # _inp "(\e[1mR\e[0m)emove hello"
    _inp "(\e[1mQ\e[0m)uit this script"
    read -n 1 -p  "[$] " _helloinput
    echo " "
    if [ "$_helloinput" = "i" ] \
        || [ "$_helloinput" = "I" ]; then
        _testrun
        #_check
        _download
        #_remove
        _install
        _postwork
    # elif [ "$_helloinput" = "r" ] \
    #    || [ "$_helloinput" = "R" ]; then
    #    _remove
    #    _postwork
    elif [ "$_helloinput" = "q" ] \
        || [ "$_helloinput" = "Q" ]; then
        exit
    else
        clear
        _ascii
        _err "I'm sorry, but that is not a valid input."
        _hello
    fi
}

# exit if no X11 session is found
_display(){
    _do "Checking for display manager ..."
    if [ ! $XDG_SESSION_TYPE = "x11" ]; then
        _err "I'm sorry, but only X11 is currently supported. You can help to port this to Wayland by joining the development! Head over to https://github.com/n4n0GH/hello and get started :)"
        _do "Exiting ..."
        exit
    fi
    clear
}

temp_file="$(mktemp -u)"
temp_dir="$(mktemp -d)"

# start order

_display
_ascii
_hello

# TODO refactor user input to their own function to reduce script size
