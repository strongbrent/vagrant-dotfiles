SHELL = /bin/bash

.PHONY: vm provision 

vm:
	vagrant up

provision:
	vagrant provision

.PHONY: host

host:
	(cd scripts/host && ./bootstrap.sh)

.PHONY: bin

bin:
	(cd scripts/bin && ./mk_bin.sh)

