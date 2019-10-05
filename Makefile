SHELL = /bin/bash

.PHONY: vm provision 

vm:
	vagrant up

provision:
	vagrant provision

.PHONY: host

host:
	scripts/host/bootstrap.sh
