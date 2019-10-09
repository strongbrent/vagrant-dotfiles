#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"

# Global Variables (over-write function Globals)
BASHRC="${HOME}/.profile"
ZSHRC="${HOME}/.zshrc"

# Global Array
shell_envs=(
    "${BASHRC}"
    "${ZSHRC}"
)

# --- Helper Functions ---------------------------------------------------

# Installs Oh-My-Zsh
install_ohmyzsh() {
    local -r shell_pkg="zsh"
    local -r pkg="oh-my-zsh"
    local -r pkg_dir="${HOME}/.${pkg}"

    if found_cmd "${shell_pkg}"; then
        echo_task "Shell package already installed: ${shell_pkg}"
    else
        echo_task "Installing shell package: ${shell_pkg}"
        brew install "${shell_pkg}"
    fi

    if found_dir "${pkg_dir}"; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended

    echo_task "Installing plugin packages: zsh-syntax-highlighting, zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${pkg_dir}/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${pkg_dir}/custom/plugins/zsh-autosuggestions

    if ! found_file "${ZSHRC}"; then
        error_exit "ERROR: ${ZSHRC} does not exist"
    fi

    echo_task "Writing zsh theme to: ${ZSHRC}"
    local -r orig_theme='ZSH_THEME="robbyrussell"'
    local -r new_theme='ZSH_THEME="bira"'
    replace_line "${orig_theme}" "${new_theme}" "${ZSHRC}"

    echo_task "Writing plugins to: ${ZSHRC}"
    local -r orig_plugins="plugins=(git)"
    local -r new_plugins="plugins=(git zsh-syntax-highlighting zsh-autosuggestions)"
    replace_line "${orig_plugins}" "${new_plugins}" "${ZSHRC}"

    # write additional aliases to SHELL initialization scripts
    for i in "${shell_envs[@]}"
    do
        if ! found_file "${i}"; then
            error_exit "ERROR: ${i} does not exist"
        fi

        echo_task "Exporting additional PATH info to: ${i}"
        echo "" >> "${i}"
        echo "# My PATH" >> "${i}"
        echo 'export PATH=${HOME}/bin:${HOME}/.local/bin:${PATH}' >> "${i}"

        echo_task "Writing additional aliases to: ${i}"
        echo "" >> "${i}"
        echo "# My Aliases" >> "${i}"
        echo "alias update='brew update && brew upgrade && brew cleanup'" >> "${i}"
    done
}

# Installs Ultimate vimrc
install_vimrc() {
    local -r ed_pkg="vim"
    local -r pkg_name="Ultimate .vimrc"
    local -r pkg_dir="${HOME}/.vim_runtime"

    if found_cmd "${ed_pkg}"; then
        echo_task "Editor package already installed: ${ed_pkg}"
    else
        echo_task "Installing editor package: ${ed_pkg}"
        brew install "${ed_pkg}"
    fi

    if found_dir "${pkg_dir}"; then
        echo_task "Package already installed: ${pkg_name}"
        return
    fi

    echo_task "Installing package: ${pkg_name}"
    git clone --depth=1 https://github.com/amix/vimrc.git "${pkg_dir}"
    sh "${pkg_dir}"/install_awesome_vimrc.sh

    local -r my_configs="${pkg_dir}/my_configs.vim"
    echo_task "Disabling section folding in: ${my_configs}"
    touch "${my_configs}"
    echo 'set nofoldenable' > "${my_configs}"

    # Add alias to update ultimate vimrc
    for i in "${shell_envs[@]}"
    do
        if ! found_file "${i}"; then
            error_exit "ERROR: ${i} does not exist"
        fi

        echo_task "Writing ${pkg_name} update alias to: ${i}"
        echo "" >> "${i}"
        echo "# For ${pkg_name}" >> "${i}"
        echo 'alias vimrc_update="pushd ${HOME}/.vim_runtime && git pull --rebase && popd"' >> "${i}"
    done
}


# --- Main Function ------------------------------------------------------
main() {

    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh

    echo_header "Installing: Ultimate .vimrc"
    install_vimrc
}


main "$@"

