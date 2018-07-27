.PHONY:all
all:
	cd ./src && $(MAKE)

.PHONY:release
release:
	cd ./src && $(MAKE) VER=$(VER)
	mkdir -p ./releases/$(VER)
	cp ./.build/hackrom.rom ./releases/$(VER)/
	cp ./.build/hackrom.lst ./releases/$(VER)/
	cp ./doc/manual.md ./releases/$(VER)/

