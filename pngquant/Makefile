build: all

all: src/Cargo.toml

src/Cargo.toml: ../.gitmodules
	../scripts/fetch-submodule src && touch src/Cargo.toml

src/lib/Cargo.toml: ../.gitmodules src/Cargo.toml
	../scripts/fetch-submodule src/lib && touch src/lib/Cargo.toml

.PHONY: build all install clean
