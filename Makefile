SHELL = /bin/bash

.PHONY: vm provision status

vm:
	vagrant up

provision:
	vagrant provision

status:
	vagrant status

.PHONY: host

host:
	(cd scripts/host && ./bootstrap-ubuntu.sh)

.PHONY: bin

bin:
	(cd scripts/bin && ./mk_bin.sh)

