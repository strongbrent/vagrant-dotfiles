#!/usr/bin/env bash

source /vagrant/scripts/lib/functions.sh

# --- Helper Functions ---------------------------------------------------

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

    echo_task "Installing package: ${pkg} for legacy python"
    pip install "${pkg}"

    echo_task "Installing package: ${pkg} for python3"
    pip3 install "${pkg}"
}

# Installs AWS IAM Authenticator
install_aws_iam_authenticator() {
    local -r pkg_name="AWS IAM Authenticator"
    local -r pkg_command="aws-iam-authenticator"
    local -r pkg_url="https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/${pkg_command}"

    if found_cmd "${pkg_command}"; then
        echo_task "Pakcage already installed: ${pkg_name}"
        return
    fi

    echo_task "Installing package: ${pkg_name}"
    curl -o "${pkg_command}" "${pkg_url}"
    chmod +x ./"${pkg_command}"
    sudo mv -v ./"${pkg_command}" /usr/local/bin/"${pkg_cmd}"
}

# One-click installation of a speficied version of the chefdk
install_chef() {
    local -r pkg="chefdk"
    local -r pkg_cmd="knife"
    local -r pkg_version="15.3.14"

    if found_cmd ${pkg_cmd}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s -L https://omnitruck.chef.io/install.sh | sudo bash -s -- -v ${pkg_version}
}

# One-click installation of the latest docker
install_docker() {
    local -r pkg="docker"
    local -r pkg_script="${get-docker.sh}"

    if found_cmd "${pkg}"; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -fsSL https://get.docker.com -o ${pkg_script}
    sh ${pkg_script}

    echo_task "Adding vagrant user to docker group"
    sudo usermod -aG docker vagrant

    if found_file "${pkg_script}"; then
        echo_task "Removing installation script for: ${pkg}"
        rm -fv "${pkg_script}"
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
    local -r pkg_name="golang"
    local -r pkg_dir="${HOME}/.go"

    if found_dir ${pkg_dir}; then
        echo_task "Package already installed: ${pkg_name}"
        return
    fi

    echo_task "Installing package: ${pkg_name}"
    curl -s https://raw.githubusercontent.com/canha/golang-tools-install-script/master/goinstall.sh | bash &> /dev/null

    echo_task "Writing ${pkg} configuration to ${ZSHRC}"
    echo '# For Golang' >> "${ZSHRC}"
    echo 'export GOROOT=${HOME}/.go' >> "${ZSHRC}"
    echo 'export PATH=$GOROOT/bin:$PATH' >> "${ZSHRC}"
    echo 'export GOPATH=${HOME}/go' >> "${ZSHRC}"
    echo 'export PATH=$GOPATH/bin:$PATH' >> "${ZSHRC}"
}

# One click installation of helm
install_helm() {
    local -r pkg_cmd="helm"
    local -r pkg_url="https://git.io/get_helm.sh"

    if found_cmd "${pkg_cmd}"; then
        echo_task "Package already installed: ${pkg_cmd}"
        return
    fi

    echo_task "Installing package: ${pkg_cmd}"
    curl -L "${pkg_url}" | bash
}

# One-click installation of the Heroku CLI
install_heroku() {
    local -r pkg_cmd="heroku"

    if found_cmd ${pkg_cmd}; then
        echo_task "Package already installed: ${pkg_cmd}"
        return
    fi

    echo_task "Installing package: ${pkg_cmd}"
    curl https://cli-assets.heroku.com/install-ubuntu.sh | sh
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

# Required SRE packages
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
    local -r pkg="packer"
    local -r pkg_script="packer-install.sh"

    if found_cmd ${pkg}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s -LO https://raw.github.com/robertpeteuil/packer-installer/master/packer-install.sh
    chmod u+x ${pkg_script}
    ./${pkg_script} -a

    if found_file "${HOME}/${pkg_script}"; then
        echo_task "Removing installation script for: ${pkg}"
        rm -fv ${pkg_script}
    fi
}

# One-click installation of pyenv
install_pyenv() {
    local -r pkg="pyenv"
    local -r pkg_dir="${HOME}/.${pkg}"

    if found_dir "${pkg_dir}"; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s https://pyenv.run | bash

    # fix for SHELL initialization scripts
    for i in "${shell_envs[@]}"
    do
        if ! found_file "${i}"; then
            error_exit "ERROR: ${i} does not exist"
        fi

        echo_task "Writing ${pkg} configuration to: ${i}"
        echo "" >> "${i}"
        echo "# For ${pkg}" >> "${i}"
        echo "export PATH=\"${pkg_dir}/bin:\$PATH\"" >> "${i}"
        echo "eval \"\$(pyenv init -)\"" >> "${i}"
        echo "eval \"\$(pyenv virtualenv-init -)\"" >> "${i}"
        echo "" >> "${i}"
    done
}

# One-click installer for specified version of Terraform
install_terraform() {
    local -r pkg="terraform"
    local -r pkg_script="terraform-install.sh"

    if found_cmd ${pkg}; then
        echo_task "Package already installed: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    curl -s -LO https://raw.github.com/robertpeteuil/terraform-installer/master/terraform-install.sh
    chmod u+x ${pkg_script}
    ./${pkg_script} -a -i 0.11.11

    if found_file "${HOME}/${pkg_script}"; then
        echo_task "Removing installation script for: ${pkg}"
        rm -fv ${pkg_script}
    fi
}

install_terraform12() {
    local -r pkg_cmd="terraform"
    local -r pkg_name="${pkg_cmd}12"
    local -r pkg_version="0.12.11"
    local -r pkg_file="terraform_${pkg_version}_linux_amd64.zip"
    local -r pkg_url="https://releases.hashicorp.com/terraform/${pkg_version}/${pkg_file}"

    if found_cmd "${pkg_name}"; then
        echo_task "Package already installed: ${pkg_name}"
        return
    fi

    echo_task "Installing package: ${pkg_name}"
    wget -q "${pkg_url}"
    unzip ${pkg_file}
    sudo mv -v "${pkg_cmd}" /usr/local/bin/"${pkg_name}"

    if found_file "${HOME}/${pkg_file}"; then
        echo_task "Removing installation script for: ${pkg_name}"
        rm -fv "${pkg_file}"
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

        echo_task "Writing ${pkg_name} update alias to: ${i}"
        echo "" >> "${i}"
        echo "# For ${pkg_name}" >> "${i}"
        echo 'alias vimrc_update="pushd ${HOME}/.vim_runtime && git pull --rebase && popd"' >> "${i}"
    done
}

# Installs zsh-nvm
install_zsh-nvm() {
    local -r pkg="zsh-nvm"
    local -r pkg_dir="${HOME}/.${pkg}"

    if found_dir "${pkg_dir}"; then
        echo_task "Package already instavaled: ${pkg}"
        return
    fi

    echo_task "Installing package: ${pkg}"
    git clone https://github.com/lukechilds/zsh-nvm.git "${pkg_dir}"

    ### NOTE: this only works in ZSH ###
    # write configuration to SHELL initialization script
    if ! found_file "${ZSHRC}"; then
        error_exit "ERROR: ${ZSHRC} does not exist"
    fi

    echo_task "Writing additional configuration to: ${ZSHRC}"
    echo "" >> "${ZSHRC}"
    echo "" >> "${ZSHRC}"
    echo "# For ${pkg}" >> "${ZSHRC}"
    echo "source ${pkg_dir}/zsh-nvm.plugin.zsh" >> "${ZSHRC}"

    /usr/bin/zsh -i -c echo " ... installing ${pkg}"
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
    echo_header "Installing: required packages"
    install_packages

    echo_header "Installing: oh-my-zsh"
    install_ohmyzsh

    echo_header "Installing: Ultimate .vimrc"
    install_vimrc

    echo_header "Installing: pyenv"
    install_pyenv

    echo_header "Installing: golang"
    install_golang

    echo_header "Installing: ansible"
    install_ansible

    echo_header "Installing: chefdk"
    install_chef

    echo_header "Installing: docker"
    install_docker

    echo_header "Installing: docker compose"
    install_docker-compose

    echo_header "Installing: kubernetes"
    install_kubernetes

    echo_header "Installing: minikube"
    install_minikube

    echo_header "Installing: helm"
    install_helm

    echo_header "Installing: packer"
    install_packer

    echo_header "Installing: terraform"
    install_terraform

    echo_header "Installing: terraform 0.12.x"
    install_terraform12

    echo_header "Installing: awsume"
    install_awsume

    echo_header "Installing: aws-cli"
    install_awscli

    echo_header "Installing: zsh-nvm"
    install_zsh-nvm

    echo_header "Installing: Heroku CLI"
    install_heroku

    echo_header "Installing: AWS IAM Authenticator"
    install_aws_iam_authenticator

    echo_header "Configuring: Setting Timezone"
    echo_task "Setting Timezone to: America/Vancouver"
    sudo timedatectl set-timezone America/Vancouver

    echo_header "Switching Default Shell: zsh"
    modify_shell
}

main "$@"

