ORIGINAL:=../hackrom-1.18
OUTPUT:=../.build
CHECKSUM:=md5sum
TASS:=64tass --m65xx --nostart -Wall -Wno-implied-reg
MKDIR:=mkdir -p

.PHONY:all
all:
	$(MKDIR) $(OUTPUT)
	$(TASS) hackrom.s65 -L$(OUTPUT)/hackrom.lst -o$(OUTPUT)/hackrom.rom
	$(CHECKSUM) $(OUTPUT)/hackrom.rom
	$(CHECKSUM) $(ORIGINAL)/bin/HACKROM
#	cmp $(OUTPUT)/hackrom.rom $(ORIGINAL)/bin/HACKROM || sh -c 'diff <(dump $(OUTPUT)/hackrom.rom) <(dump $(ORIGINAL)/bin/HACKROM) | head -n 5'
