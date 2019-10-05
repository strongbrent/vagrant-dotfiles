SHELL = /bin/bash

.PHONY: vm provision 

vm:
	vagrant up

provision:
	vagrant provision
