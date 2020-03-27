# Windows Terminal
cinst microsoft-windows-terminal -r -y

# Windows Subsystem for Linux
cinst Microsoft-Windows-Subsystem-Linux -r -y -source windowsFeatures

# Ubuntu 18.04
### Requires a reboot first ###
# cinst wsl-ubuntu-1804 -r -y

# Utilities
cinst openssh -r -y

# Editors
cinst vim -r -y
cinst notepadplusplus -r -y 

# Development
cinst git -r -y
cinst make -r -y

## vscode
cinst vscode -r -y
cinst vscode-go -r -y 
cinst vscode-ansible -r -y
cinst vscode-ruby -r -y
cinst vscode-python -r -y
cinst vscode-java -r -y
cinst vscode-kubernetes-tools -r -y
cinst vscode-docker -r -y
cinst vscode-powershell -r -y

## languages
cinst python -r -y
cinst golang -r -y
cinst openjdk11 -r -y

## database
cinst dbeaver -r -y

## webdev
cinst postman -r -y

# Browsers
cinst firefox -r -y
cinst googlechrome -r -y

# Communication
cinst slack -r -y

# Entertainment
cinst spotify -r -y

# Virtualization
cinst virtualbox -r -y
cinst vagrant -r -y
