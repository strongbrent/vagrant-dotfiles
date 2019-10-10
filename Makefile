SHELL = /bin/bash

.PHONY: vm provision reload status

vm:
	vagrant up

provision:
	vagrant provision

reload:
	vagrant reload

status:
	vagrant status

.PHONY: host host_force

host:
	(cd scripts/host && ./execute_bootstrap.sh)

host_force:
	(cd scripts/host && ./execute_bootstrap.sh -y)

.PHONY: bin

bin:
	(cd scripts/bin && ./mk_bin.sh)

