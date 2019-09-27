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
    if found_cmd ansible; then
        echo_task "Already installed package: ansible"
        return
    fi

    echo_task "Installing package: ansible"
    sudo apt-add-repository --yes --update ppa:ansible/ansible
    sudo apt-get update -qq
    sudo apt-get install -y -qq ansible
}

# Installs latest awscli
install_awscli() {
    if found_cmd aws; then
        echo_task "Already installed package: awscli"
        return
    fi

    echo_task "Installing package: awscli"
    curl -s "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
    unzip awscli-bundle.zip
    sudo ${HOME}/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

    if found_file "${HOME}/awscli-bundle.zip"; then
        echo_task "Removing installation bundle for: awscli"
        rm -fv "${HOME}/awscli-bundle.zip"
    fi
}

# Installs latest awsume
install_awsume() {
    if found_cmd awsume; then
        echo_task "Already installed package: awsume"
        return
    fi

    echo_task "Installing package: awsume"
    pip install awsume
}

# One-click installation of a speficied version of the chefdk
install_chef() {
    if found_cmd knife; then
        echo_task "Package already installed: chefdk"
        return
    fi

    echo_task "Installing package: chefdk"
    curl -s -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v 15.3.14
}

# One-click installation of the latest docker
install_docker() {
    local -r install_script="${HOME}/get-docker.sh"

    if found_cmd docker; then
        echo_task "Package already installed: docker"
        return
    fi

    echo_task "Installing package: docker"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh

    echo_task "Adding vagrant user to docker group"
    sudo usermod -aG docker vagrant

    if found_file "${install_script}"; then
        echo_task "Removing installation script for: docker"
        rm -fv "${install_script}"
    fi
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
    local -r K8_version="1.6.0"

    if found_cmd kubectl; then
        echo_task "Package already installed: kubectl"
        return
    fi

    echo_task "Installing package: kubectl"
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -qq
    sudo apt-get install -y -qq kubectl
}

# Installs latest version of minikube
install_minikube() {
    if found_cmd minikube; then
        echo_task "Package already installed: minikube"
        return
    fi

    echo_task "Installing package: minikube"
    wget -q https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod 755 minikube-linux-amd64
    sudo mv -v minikube-linux-amd64 /usr/local/bin/minikube
}

# Installs Oh-My-Zsh
install_ohmyzsh() {
    if found_dir "${HOME}/.oh-my-zsh"; then
        echo_task "Package already installed: oh-my-zsh"
        return
    fi

    echo_task "Installing package: oh-my-zsh"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended

    echo_task "Installing plugin packages: zsh-syntax-highlighting, zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions

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

# Installs the latest version of the Serverless Framework
install_serverless() {
    local NVM_DIR="${HOME}/.nvm"
    local NODE_VERSION=10.16.3
    local NODE_HOME="${NVM_DIR}/versions/node/v${NODE_VERSION}"
    local SERVERLESS_PATH="${NODE_HOME}/bin/serverless"

    if found_file "${SERVERLESS_PATH}"; then
        echo_task "Package already installed: Serverless Framework"
        return
    fi

    # Install nvm
    if ! found_dir "${NVM_DIR}"; then
        echo_task "Installing package: nvm"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    fi

    # Install nodejs via nvm (whatever version of 10 that is supported by AWS Lambda)
    if ! found_dir "${NODE_HOME}"; then
        echo_task "Installing package via nvm: nodejs"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        nvm install "${NODE_VERSION}"
    fi

    # Install latest version of serverless
    echo_task "Installing package via npm: serverless"
    npm install -g serverless

    # Fix .bashrc
    echo -e "\n" >> "${HOME}/.bashrc"
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
    if found_dir "${HOME}/.vim_runtime"; then
        echo_task "Package already installed: Ultimate .vimrc"
        return
    fi

    echo_task "Installing package: Ultimate .vimrc"
    git clone --depth=1 https://github.com/amix/vimrc.git "${HOME}/.vim_runtime"
    sh "${HOME}/.vim_runtime"/install_awesome_vimrc.sh

    local -r my_configs="${HOME}/.vim_runtime/my_configs.vim"
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

    #echo_header "Installing: Serverles Framework"
    #install_serverless
}

main "$@"
