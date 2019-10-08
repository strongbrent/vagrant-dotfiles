#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"


# --- Helper Functions ---------------------------------------------------

# Installs Oh-My-Zsh
install_ohmyzsh() {
    brew cask install iterm2
    brew install zsh
}

# --- Main Function ------------------------------------------------------
main() {
    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh
}


main "$@"

