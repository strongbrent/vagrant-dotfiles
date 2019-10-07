#!/usr/bin/env bash

dir="$(pwd)"
parentdir="$(dirname "${dir}")"

source "${parentdir}/lib/functions.sh"


# --- Helper Functions ---------------------------------------------------

# Configures Gnome Settings
config_gnome_settings() {
    local -r gnome_favs="['firefox.desktop', 'google-chrome.desktop', 'terminator.desktop', 'postman_postman.desktop', 'code_code.desktop', 'org.gnome.gedit.desktop', 'org.gnome.Nautilus.desktop', 'gnome-calculator_gnome-calculator.desktop', 'org.gnome.Screenshot.desktop', 'slack_slack.desktop', 'spotify_spotify.desktop', 'virtualbox.desktop', 'transmission-gtk.desktop', 'org.gnome.Software.desktop']"

    # gnome dock favorites
    my_favs=$(gsettings get org.gnome.shell favorite-apps)
    if [ "${gnome_favs}" == "${my_favs}" ]; then
        echo_task "Already configured: Gnome Dock Favorites"
    else
        echo_task "Configuring: Gnome Dock Favorites"
        gsettings set org.gnome.shell favorite-apps "${gnome_favs}"
    fi

    # make the clock show seconds
    clock_seconds=$(gsettings get org.gnome.desktop.interface clock-show-seconds)
    if [ "${clock_seconds}" == "true" ]; then
        echo_task "Already configured: Gnome Desktop Clock - show seconds"
    else
        echo_task "Configuring: Gnome Desktop Clock - show seconds"
        gsettings set org.gnome.desktop.interface clock-show-seconds true
    fi

    # make the clock show weekdays
    clock_weekday=$(gsettings get org.gnome.desktop.interface clock-show-weekday)
    if [ "${clock_weekday}" == "true" ]; then
        echo_task "Already configured: Gnome Desktop Clock - show weekday"
    else
        echo_task "Configuring: Gnome Desktop Clock - show weekday"
        gsettings set org.gnome.desktop.interface clock-show-weekday true
    fi

    # make the battery show percentage
    battery_percentage=$(gsettings get org.gnome.desktop.interface show-battery-percentage)
    if [ "${battery_percentage}" == "true" ]; then
        echo_task "Already configured: Gnome Desktop Battery - show percentage"
    else
        echo_task "Configuring: Gnome Desktop Battery - show percentage"
        gsettings set org.gnome.desktop.interface show-battery-percentage true
    fi
}

# Configure Vboxusers Group
config_vboxusers() {
    local -r vbu_group="vboxusers"

    if groups | grep "${vbu_group}" &> /dev/null; then
        echo_task "${USER} already added to group: ${vbu_group}"
        return
    fi

    echo_task "Adding ${USER} to group: ${vbu_group}"
    sudo usermod -a -G "${vbu_group}" "${USER}"
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
	echo "${USER}   ALL=(ALL:ALL) NOPASSWD:ALL" > "${tmp_path}"
	sudo chown root:root "${tmp_path}"
	sudo mv "${tmp_path}" ${sudoers_path}
}

# Installs Google Chrome
install_chrome() {
    local -r pkg="google-chrome"
    local -r pkg_file="google-chrome-stable_current_amd64.deb"

    if found_cmd ${pkg}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -O https://dl.google.com/linux/direct/${pkg_file}
    sudo gdebi -n ${pkg_file}

    if found_file ${pkg_file}; then
        echo_task "Removing: ${pkg_file}"
        rm -f ./${pkg_file}
    fi
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
        echo "alias update='sudo apt-get update && sudo apt-get upgrade'" >> "${i}"
        echo "alias autoremove='sudo apt autoremove'" >> "${i}"
        echo "alias trimsd='sudo fstrim -av'" >> "${i}"
    done
}

# Required Host Packages
install_packages() {
    pkgs=(
        apt-file
        apt-transport-https
        aptitude
        build-essential
        bzip2
        curl
        firefox
        gdebi-core
        gnome-shell-extension-gsconnect-browsers
        gnome-tweaks
        libglib2.0-bin
        linux-headers-generic
        net-tools
        openssh-server
        screen
        snapd
        terminator
        tlp
        transmission
        tmux
        tree
        ubuntu-restricted-addons
        ubuntu-restricted-extras
        unzip
        vagrant
        vim
        virtualbox
        virtualbox-dkms
        virtualbox-ext-pack
        wget
        youtube-dl
        zsh
    )

    sudo apt-get update -qq

    for i in "${pkgs[@]}"
    do
        echo_task "Processing package: ${i}"
        sudo apt-get install -y -qq ${i}
    done
}

# Installs a specified snap package
install_snap() {
    if snap list ${1} &> /dev/null; then
        echo_task "Snap package already installed: ${1}"
        return
    fi

    echo_task "Installing snap package: ${1}"
    if [[ "${2}" == "classic"  ]]; then
        sudo snap install ${1} --classic
        return
    fi

    if [[ "${2}" == "edge"  ]]; then
        sudo snap install ${1} --edge
        return
    fi

    sudo snap install ${1}
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
    exts=(
        donjayamanne.githistory
        ms-vscode-remote.vscode-remote-extensionpack
        yzhang.markdown-all-in-one
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

# Changes the default shell to ZSH
modify_shell() {
    local -r current_shell=$(echo ${SHELL})
    local -r new_shell="/bin/zsh"

    if [ ${current_shell} == ${new_shell} ]; then
        echo_task "Shell is already set to use: ${current_shell}"
        return
    fi

    echo_task "Setting SHELL to use: ${new_shell}"
    sudo usermod -s ${new_shell} ${USER}
}


# --- Main Function ------------------------------------------------------
main() {

    ### Get confirmation to proceed ###
    echo "Warning. This script installs software and overwrite files in your HOME directory."
    if ! confirm "Do you with to continue? [y/N] "; then
        echo_task "Goodbye"
	exit
    fi
    ### Get confirmation to proceed ###

    echo_header "Creating: passwordless sudo"
    create_sudoer

    echo_header "Installing: Required Packages"
    install_packages

    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh

    echo_header "Installing: Ultimate .vimrc"
    install_vimrc

    echo_header "Installing: Chrome"
    install_chrome

    echo_header "Installing: Postman"
    install_snap postman

    echo_header "Installing: VS Code"
    install_snap code classic

    echo_header "Installing: VS Code Extensions"
    install_vs_code_extensions

    echo_header "Installing: Dbeaver"
    install_snap dbeaver-ce edge

    echo_header "Installing: Slack"
    install_snap slack classic

    echo_header "Installing: Spotify"
    install_snap spotify

    echo_header "Configuring: Vboxusers Group"
    config_vboxusers

    echo_header "Configuring: Gnome Setting"
    config_gnome_settings

    echo_header "Switching Default Shell: zsh"
    modify_shell
}

main "$@"
