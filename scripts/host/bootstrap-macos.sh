#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"


# --- Helper Functions ---------------------------------------------------

# Installs Host Packages
install_packages() {
    pkgs=(
        vim
        zsh
    )

    cask_pkgs=(
        iterm2
    )

    # install brew packages
    for i in "${pkgs[@]}"
    do
        echo_task "Processing brew package: ${i}"
        brew install "${i}"
    done

    # install cask packages
    for i in "${cask_pkgs[@]}"
    do
        echo_task "Processing cask package: ${i}"
        brew cask install "${i}"
    done
}

# Installs Oh-My-Zsh
install_ohmyzsh() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended
}

# Installs Ultimate vimrc
install_vimrc() {
    local -r pkg_name="Ultimate .vimrc"
    local -r pkg_dir="${HOME}/.vim_runtime"

    echo_task "Installing package: ${pkg_name}"
    git clone --depth=1 https://github.com/amix/vimrc.git "${pkg_dir}"
    sh "${pkg_dir}"/install_awesome_vimrc.sh
}


# --- Main Function ------------------------------------------------------
main() {

    echo_header "Installing: Required Packages"
    install_packages

    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh

    echo_header "Installing: Ultimate .vimrc"
    install_vimrc
}


main "$@"

