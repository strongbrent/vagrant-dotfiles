#!/usr/bin/env bash

# Global Variables
export DEBIAN_FRONTEND=noninteractive
PYENV_ROOT="${HOME}/.pyenv"
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"

# Global Array
shell_envs=(
    "${BASHRC}"
    "${ZSHRC}"
)

# --- Helper Functions ---------------------------------------------------

# DESC: Prints a header statement to standard out
# ARGS: S1 (OPT): message string
# OUT: NONE
echo_header() {
    # Function variables/constants
    local -r pre="===>"
    local -r msg="${1:-Empty Header}"

    # Run Commands
    echo ""
    echo "${pre} ${msg}"
}

# DESC: Prints a task description
# ARGS: $1 (OPT): message string
# OUT:  NONE
echo_task() {
    # Function variables/constants
    local -r pre="....."
    local -r msg="${1:-Empty task}"

    # Run commands
    echo "${pre} ${msg}"
}

# DESC: Safe script exit (copy to libs)
# ARGS: $1 (OPT): Error message string
# OUT:  1
error_exit() {
    echo "${1:-UNKNOWN ERROR}"

    # handle exits from shell or function but don't exit interactive shell
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
}

# DESC: Checks to see if a command exists
# ARGS: $1 (REQ): name of command
# OUT:  0  -> if found
#       !0 -> if not found
found_cmd() {
    command -v "${1}" &>/dev/null
}

# DESC: Checks to see if a directory exists
# ARGS: $1 (REQ): name of directory
# OUT:  0  -> if found
#       !0 -> if not found
found_dir() {
    test -d "${1}" &>/dev/null
}

# DESC: Checks to see if a file exists
# ARGS: $1 (REQ): name of file
# OUT:  0  -> if found
#       !0 -> if not found
found_file() {
    test -f "${1}" &>/dev/null
}

# Installer for latest Ansible
install_ansible() {
    local -r pkg="ansible"

    if found_cmd ${pkg}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${pkg}"
}

# Installs latest awscli
install_awscli() {
    local -r pkg="awscli"
    local -r pkg_file="${pkg}-bundle.zip"

    if found_cmd aws; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s "https://s3.amazonaws.com/aws-cli/${pkg_file}" -o "${pkg_file}"
    unzip "${pkg_file}"
    sudo ${HOME}/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

    if found_file "${HOME}/${pkg_file}"; then
        echo_task "Removing installation bundle for: ${pkg}"
        rm -fv "${HOME}/awscli-bundle.zip"
    fi
}

# Installs latest awsume
install_awsume() {
    local -r pkg="awsume"

    if found_cmd ${pkg}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    pip install "${pkg}"
}

# One-click installation of a speficied version of the chefdk
install_chef() {
    local -r pkg="${pkg}"
    local -r pkg_version="15.3.14"

    if found_cmd knife; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${pkg_version}
}

# One-click installation of the latest docker
install_docker() {
    local -r pkg="docker"
    local -r install_script="${get-docker.sh}"

    if found_cmd "${pkg}"; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -fsSL https://get.docker.com -o ${install_script}
    sh ${install_script}

    echo_task "Adding vagrant user to docker group"
    sudo usermod -aG docker vagrant

    if found_file "${install_script}"; then
        echo_task "Removing installation script for: ${pkg}"
        rm -fv "${install_script}"
    fi
}

# One-click installation of the latest docker-compose
install_docker-compose() {
    local -r pkg="docker-compose"

    if found_cmd "${pkg}"; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s https://api.github.com/repos/docker/compose/releases/latest \
        | grep browser_download_url \
        | grep docker-compose-Linux-x86_64 \
        | cut -d '"' -f 4 \
        | wget -qi -
    chmod +x docker-compose-Linux-x86_64
    sudo mv docker-compose-Linux-x86_64 /usr/local/bin/${pkg}
}

# One-click installation of latest golang
install_golang() {
    if found_dir "${HOME}/.go"; then
        echo_task "Package already installed: golang"
        return
    fi

    echo_task "Installing package: golang"
    curl -s https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash &> /dev/null

    echo_task "Writing Golang configuration to ${ZSHRC}"
    echo '# GoLang' >> "${ZSHRC}"
    echo 'export GOROOT=${HOME}/.go' >> "${ZSHRC}"
    echo 'export PATH=$GOROOT/bin:$PATH' >> "${ZSHRC}"
    echo 'export GOPATH=${HOME}/go' >> "${ZSHRC}"
    echo 'export PATH=$GOPATH/bin:$PATH' >> "${ZSHRC}"
}

# Installs latest version of kubernetes (via apt)
install_kubernetes() {
    local -r pkg="kubectl"
    local -r K8_version="1.6.0"

    if found_cmd ${pkg}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -qq
    sudo apt-get install -y -qq ${pkg}
}

# Installs latest version of minikube
install_minikube() {
    local -r pkg="minikube"

    if found_cmd ${pkg}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    wget -q https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod 755 minikube-linux-amd64
    sudo mv -v minikube-linux-amd64 /usr/local/bin/${pkg}
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
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${pkg_dir}/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${pkg_dir}/custom/plugins/zsh-autosuggestions

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

        echo_task "Writing additional aliases to: ${i}"
        echo "" >> "${i}"
        echo "# My Aliases" >> "${i}"
        echo "alias update='sudo apt-get update && sudo apt-get upgrade'" >> "${i}"
        echo "alias autoremove='sudo apt autoremove'" >> "${i}"
        echo "alias trimsd='sudo fstrim -av'" >> "${i}"
    done
}

# Useful SRE packages
install_packages() {
    pkgs=(
        apt-file
        apt-transport-https
        aptitude
        arpwatch
        atop
        bats
        bmon
        build-essential
        bzip2
        curl
        default-jdk
        direnv
        dstat
        dos2unix
        ethtool
        glances
        gnupg-agent
        htop
        iftop
        iotop
        iptraf
        jq
        libffi-dev
        libbz2-dev
        libsqlite3-dev
        llvm
        make
        mtr
        multitail
        net-tools
        netcat
        nethogs
        ngrep
        nmap
        openssh-server
        parallel
        python-pip
        python3-pip
        ruby-full
        screen
        software-properties-common
        tcpdump
        tlp
        tmux
        tree
        unzip
        wget
        zlib1g-dev
        zsh
    )

    sudo apt-get update -qq

    for i in "${pkgs[@]}"
    do
        echo_task "Processing package: ${i}"
        sudo apt-get install -y -qq ${i}
    done
}

# One-click intallation for specified version of Packer
install_packer() {
    if found_cmd packer; then
        echo_task "Package already installed: packer"
        return
    fi

    echo_task "Installing package: packer"
    curl -s -LO https://raw.github.com/robertpeteuil/packer-installer/master/packer-install.sh
    chmod u+x packer-install.sh
    ./packer-install.sh -a

    if found_file "${HOME}/packer-install.sh"; then
        echo_task "Removing installation script for: packer"
        rm -fv packer-install.sh
    fi
}

# One-click installation of pyenv
install_pyenv() {
    if found_dir "${PYENV_ROOT}"; then
        echo_task "Package already installed: pyenv"
        return
    fi

    echo_task "Installing package: pyenv"
    curl -s https://pyenv.run | bash

    # fix for SHELL initialization scripts
    for i in "${shell_envs[@]}"
    do
        if ! found_file "${i}"; then
            error_exit "ERROR: ${i} does not exist"
        fi

        echo_task "Writing pyenv configuration to: ${i}"
        echo "" >> "${i}"
        echo "# For pyenv" >> "${i}"
        echo "export PATH=\"${PYENV_ROOT}/bin:\$PATH\"" >> "${i}"
        echo "eval \"\$(pyenv init -)\"" >> "${i}"
        echo "eval \"\$(pyenv virtualenv-init -)\"" >> "${i}"
        echo "" >> "${i}"
    done
}

# DESC: Replaces a line (in place) in a specified file with specified text
# ARGS: $1 (REQ): original line of text
#       $2 (REQ): new line of text
#       $3 (REQ): specified file
# OUT:  NONE
replace_line() {
    sed -i "s/${1}/${2}/g" "${3}"
}

# One-click installer for specified version of Terraform
install_terraform() {
    if found_cmd terraform; then
        echo_task "Package already installed: terraform"
        return
    fi

    echo_task "Installing package: terraform"
    curl -s -LO https://raw.github.com/robertpeteuil/terraform-installer/master/terraform-install.sh
    chmod u+x terraform-install.sh
    ./terraform-install.sh -a -i 0.11.11

    if found_file "${HOME}/terraform-install.sh"; then
        echo_task "Removing installation script for: terraform"
        rm -fv terraform-install.sh
    fi
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

        echo_task "Writing Ultimate Vimrc update alias to: ${i}"
        echo "" >> "${i}"
        echo "# For Ultimate Vimrc" >> "${i}"
        echo 'alias vimrc_update="pushd ${HOME}/.vim_runtime && git pull --rebase && popd"' >> "${i}"
    done
}

# Installs zsh-nvm
install_zsh-nvm() {
    local -r NVM_HOME="${HOME}/.zsh-nvm"

    if found_dir "${NVM_HOME}"; then
        echo_task "Package already instavaled: zsh-nvm"
        return
    fi

    echo_task "Installing package: zsh-nvm"
    git clone https://github.com/lukechilds/zsh-nvm.git "${NVM_HOME}"

    # write configuration to SHELL initialization script
    if ! found_file "${ZSHRC}"; then
        error_exit "ERROR: ${ZSHRC} does not exist"
    fi

    echo_task "Writing additional configuration to: ${ZSHRC}"
    echo "" >> "${ZSHRC}"
    echo "" >> "${ZSHRC}"
    echo "# For nvm" >> "${ZSHRC}"
    echo "source ${HOME}/.zsh-nvm/zsh-nvm.plugin.zsh" >> "${ZSHRC}"

    /usr/bin/zsh -i -c echo " ... installing nvm"
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


# --- Main function -------------------------------------------------------
main() {
    echo_header "Installing: specified packages"
    #install_packages

    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh

    echo_header "Installing: Ultimate Vimrc"
    install_vimrc

    echo_header "Installing: pyenv"
    install_pyenv

    echo_header "Installing: Golang"
    install_golang

    echo_header "Installing: Ansible"
    install_ansible

    echo_header "Installing: Chef"
    install_chef

    echo_header "Installing: Docker CE"
    install_docker

    echo_header "Installing: Docker Compose"
    install_docker-compose

    echo_header "Installing: Kubernetes"
    install_kubernetes

    echo_header "Installing: minikube"
    install_minikube

    echo_header "Installing: Packer"
    install_packer

    echo_header "Installing: Terraform"
    install_terraform

    echo_header "Installing: Awsume"
    install_awsume

    echo_header "Installing: AWS CLI"
    install_awscli

    echo_header "Installing: zsh-nvm"
    install_zsh-nvm

    echo_header "Switching Default Shell: zsh"
    modify_shell
}

main "$@"

