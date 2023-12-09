NIX_FILES = $(shell find . -name '*.nix' -type f)

.PHONY: all build run rebuild

all: build

build:
	./build.sh

run:
	./run.sh

ssh:
	ssh-keygen -R "[localhost]:2223"
	ssh -o StrictHostKeychecking=no -p 2223 homefree@localhost
