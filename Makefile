PREFIX := .compiled

.PHONY = all clean xclip pbcopy

all: game.hex

$(PREFIX)/tiles.8o: Makefile\
assets/tiles/*
		./generate-texture.py assets/tiles/splash.png splash 2 16 > $@

$(PREFIX)/font.8o $(PREFIX)/font-data.8o: Makefile generate-font.py assets/font/5.font
		./generate-font.py assets/font/5.font font 1100 $(PREFIX)

$(PREFIX)/texts.8o $(PREFIX)/texts_data.8o: Makefile assets/en.json generate-text.py
		./generate-text.py $(PREFIX) 2000 assets/en.json \

$(PREFIX)/signature.8o: Makefile ./generate-string.py
		./generate-string.py "DEFINITELY NO FISH HERE ©COWNAMEDSQUIRREL 2018" > $@

game.8o: Makefile \
$(PREFIX)/font.8o \
$(PREFIX)/texts.8o \
$(PREFIX)/texts_data.8o \
$(PREFIX)/tiles.8o \
$(PREFIX)/signature.8o \
assets/* assets/*/* sources/*.8o generate-texture.py
		cat $(PREFIX)/texts.8o > $@
		cat sources/main.8o >> $@
		cat sources/text.8o >> $@
		cat sources/utils.8o >> $@
		cat sources/tiles.8o >> $@
		cat sources/splash.8o >> $@
		cat $(PREFIX)/font.8o >> $@

		cat $(PREFIX)/tiles.8o >> $@
		cat $(PREFIX)/font_data.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@
		cat $(PREFIX)/signature.8o >> $@

game.bin: game.8o
	./octo/octo game.8o $@

game.hex: game.bin ./generate-hex.py
	./generate-hex.py game.bin $@

xclip: game.hex
	cat game.hex | xclip

pbcopy: game.hex
	cat game.hex | pbcopy

clean:
		rm -f game.bin game.8o game.hex .compiled/*
