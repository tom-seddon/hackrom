ORIGINAL:=../hackrom-1.18
OUTPUT:=../.build
CHECKSUM:=md5sum
TASS:=64tass --m65xx --nostart -Wall -Wno-implied-reg
MKDIR:=mkdir -p
CP:=cp -v

# Hmm.
ifeq ($(USER),tom)
ifeq ($(shell uname),Darwin)
CTAGS:=/opt/local/bin/ctags
TOM:=1
endif
endif

VER?=$(shell date)

.PHONY:all
all:
	$(MKDIR) $(OUTPUT)
	$(TASS) hackrom.s65 -L$(OUTPUT)/hackrom.lst -o$(OUTPUT)/hackrom.rom "-DVERSION=\"$(VER)\""
ifdef CTAGS
	@$(CTAGS) --langdef=64tass --langmap=64tass:.s65 '--regex-64tass=/^([A-Za-z0-9_]+)/\\1/' -eR .
	@$(CHECKSUM) $(OUTPUT)/hackrom.rom
endif
ifdef TOM
	@$(CP) $(OUTPUT)/hackrom.rom ~/beeb/beeb-files/stuff/65boot/0/RHACKTOM
	@$(CP) $(OUTPUT)/hackrom.rom ~/beeb/beeb-files/stuff/basic_editor/0/RHACKTOM
	@$(CP) $(OUTPUT)/hackrom.rom ~/beeb/beeb-files/stuff/hackrom/0/RHACKTOM
endif
