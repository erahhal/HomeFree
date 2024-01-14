NIX_FILES = $(shell find . -name '*.nix' -type f)

.PHONY: all build run rebuild

all: help

help:
	@echo Usage
	@echo
	@echo "  make setup              prepare machine to run"
	@echo "  make build-image        build qemu image on host"
	@echo "  make build              rebuild system from inside guest"
	@echo "  make run                run homefree and lan client images"
	@echo "  make ssh                SSH into running homefree kvm"

build-image:
	./build-image.sh

build:
	./build.sh

run:
	./run.sh

setup:
	./setup.sh

ssh:
	ssh-keygen -R "[localhost]:2223"
	ssh -o StrictHostKeychecking=no -p 2223 homefree@localhost

generate-sops-config:
	./generate-sops-config.sh
