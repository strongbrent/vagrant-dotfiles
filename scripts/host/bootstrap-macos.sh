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

# Configures dock settings
configure_dock() {
    echo_task "Moving dock to the left"
    defaults write com.apple.dock orientation left

    # ('genie', 'scale', 'suck')
    echo_task "Setting dock minimizing effect"
    defaults write com.apple.dock mineffect -string 'genie'

    echo_task "Setting dock icon size"
    defaults write com.apple.dock tilesize -int 46

    echo_task "Setting dock magnification"
    defaults write com.apple.dock magnification -bool true
    defaults write com.apple.dock largesize -int 64

    # Double-click a window's title bar to:
    # None
    # Mimimize
    # Maximize (zoom)
    echo_task "Setting action for: double-click window's title bar"
    defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Maximize"

    echo_task "Setting action for: minimize to application"
    defaults write com.apple.dock minimize-to-application -bool true

    echo_task "Setting dock autohide feature"
    defaults write com.apple.dock autohide -bool true

    echo_task "Setting dock autohide delay"
    defaults write com.apple.dock autohide-delay -float 0

    # Auto-hide animation duration
    # defaults write com.apple.dock autohide-time-modifier -float 0

    echo_task "Setting spring load on all items"
    defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

    echo_task "Setting show process indicators for running apps"
    defaults write com.apple.dock show-process-indicators -bool true

    echo_task "Setting dock persistent application icons"
    dockutil --remove all
    dockutil --add /Applications/Launchpad.app
    dockutil --add /Applications/Firefox.app
    dockutil --add /Applications/Google\ Chrome.app
    dockutil --add /Applications/iTerm.app
    dockutil --add /Applications/Postman.app
    dockutil --add /Applications/Visual\ Studio\ Code.app
    dockutil --add /Applications/TextMate.app
    dockutil --add /Applications/Calculator.app
    dockutil --add /Applications/Slack.app
    dockutil --add /Applications/Spotify.app
    dockutil --add /Applications/VirtualBox.app
    dockutil --add /Applications/Transmission.app
    dockutil --add /Applications/App\ Store.app
    dockutil --add /Applications/ --view grid --display folder --allhomes
    dockutil --add '~/Documents' --view grid --display folder --allhomes
    dockutil --add '~/Downloads' --view grid --display folder --allhomes
}

# Creates a passwordless sudo entry
create_sudoer() {
    local -r tmp_path="/tmp/${USER}"
    local -r sudoers_dir="/etc/sudoers.d"
    local -r sudoers_path="${sudoers_dir}/${USER}"

    if found_file "${sudoers_path}"; then
        echo_task "Sudoers file already created: ${sudoers_path}"
        return
    fi

    echo_task "Creating sudoers file: ${sudoers_path}"
    touch "${tmp_path}"
    chmod 0600 "${tmp_path}"
    echo "${USER} ALL = (ALL) NOPASSWD: ALL" > "${tmp_path}"
    sudo chown root:root "${tmp_path}"
    sudo mv "${tmp_path}" "${sudoers_path}"
}

# DESC: checks to see if a brew formula is installed
# ARGS: $1 (REQ): name of brew formula
# OUT:  0  -> if found
#       !0 -> if not found
found_brew() {
    brew list "${1}" &>/dev/null
}

# DESC: checks to see if a brew cask is installed
# ARGS: $1 (REQ): name of the brew cask
# OUT:  0  -> if found
#       !0 -> if not found
found_cask() {
    brew cask list "${1}" &>/dev/null
}

# DESC: installs a specified brew formula/cask
# ARGS: $1 (REQ): either 'cask' or name of the brew formula
#       $2 (OPT): name of the brew cask
install_brew() {
    if [ "$1" == 'cask' ]; then
        if found_cask "${2}"; then
            echo_task "Already installed brew cask: ${2}"
            return
        fi

        echo_task "Installing brew cask: ${2}"
        brew cask install "${2}"
        return
    fi

    if found_brew "${1}"; then
        echo_task "Already installed brew formula: ${1}"
        return
    fi

    echo_task "Installing brew formula: ${1}"
    brew install "${1}"
}

# Installs Oh-My-Zsh
install_ohmyzsh() {
    local -r pkg="oh-my-zsh"
    local -r pkg_dir="${HOME}/.${pkg}"

    if found_dir "${pkg_dir}"; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended

    echo_task "Installing plugin packages: zsh-syntax-highlighting, zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "${pkg_dir}"/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "${pkg_dir}"/custom/plugins/zsh-autosuggestions

    if ! found_file "${ZSHRC}"; then
        error_exit "ERROR: ${ZSHRC} does not exist"
    fi

    echo_task "Writing zsh theme to: ${ZSHRC}"
    local -r orig_theme='ZSH_THEME="robbyrussell"'
    local -r new_theme='ZSH_THEME="bira"'
    replace_line "${orig_theme}" "${new_theme}" "${ZSHRC}" "${OS_TYPE}"

    echo_task "Writing plugins to: ${ZSHRC}"
    local -r orig_plugins="plugins=(git)"
    local -r new_plugins="plugins=(git zsh-syntax-highlighting zsh-autosuggestions)"
    replace_line "${orig_plugins}" "${new_plugins}" "${ZSHRC}" "${OS_TYPE}"

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

# Installs specified packages
install_packages() {
    pkgs=(
        cmake
        coreutils
        curl
        dockutil
        dos2unix
        fontconfig
        freetype
        gettext
        git
        gnupg
        gnutls
        htop
        iftop
        jpeg
        jq
        kubectl
        minikube
        openssh
        openssl
        pass
        pidof
        pwgen
        readline
        shellcheck
        telnet
        tmux
        trash
        tree
        vim
        wget
        xz
        youtube-dl
        zlib
        zsh
    )

    casks=(
        dbeaver-community
        firefox
        google-chrome
        iterm2
        java
        kindle
        postman
        ringcentral
        robo-3t
        slack
        spotify
        teamviewer
        textmate
        the-unarchiver
        transmission
        tunnelblick
        vagrant
        vagrant-manager
        virtualbox-extension-pack
        visual-studio-code
        wireshark
        zoomus
    )

    brew update

    for i in "${pkgs[@]}"
    do
        echo_task "Processing brew formula: ${i}"
        install_brew "${i}"
    done

    for i in "${casks[@]}"
    do
        echo_task "Processing brew casks: ${i}"
        install_brew cask "${i}"
    done
}

# Installs Ultimate vimrc
install_vimrc() {
    local -r pkg_name="Ultimate .vimrc"
    local -r pkg_dir="${HOME}/.vim_runtime"

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

# Installs VS Code extensions
install_vs_code_extensions() {
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

    exts=(
        donjayamanne.githistory
        ms-vscode-remote.vscode-remote-extensionpack
        yzhang.markdown-all-in-one
        timonwong.shellcheck
    )

    for i in "${exts[@]}"
    do
        if code --list-extensions | grep "${i}" &> /dev/null; then
            echo_task "VS Code Extension already installed: ${i}"
            continue
        fi

        echo_task "Installing VS Code Extension: ${i}"
        code --install-extension "${i}"
    done
}


# --- Main Function ------------------------------------------------------
main() {

    echo_header "Creating: passwordless sudo"
    create_sudoer

    echo_header "Installing: Required Packages"
    install_packages

    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh

    echo_header "Installing: Ultimate .vimrc"
    install_vimrc

    echo_header "Installing: VS Code Extensions"
    install_vs_code_extensions

    echo_header "Configuring: Dock Settings"
    configure_dock
}


main "$@"
