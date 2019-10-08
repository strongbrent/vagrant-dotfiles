#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"


# --- Helper Functions ---------------------------------------------------

# Installs Host Packages
install_packages() {
    pkgs=(
        zsh
    )

    cask_pkgs=(
        iterm2
    )

    # install brew packages
    for i in "${pkgs[@]}"
    do
        echo_task "Processing brew package: ${i}"
        brew install -q "${i}"
    done

    # install cask packages
    for i in "${cask_pkgs[@]}"
    do
        echo_task "Processing cask package: ${i}"
        brew cask install -q "${i}"
    done
}

# Installs Oh-My-Zsh
install_ohmyzsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
}


# --- Main Function ------------------------------------------------------
main() {

    echo_header "Installing: Required Packages"
    install_packages

    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh
}


main "$@"

