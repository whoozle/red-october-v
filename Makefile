PREFIX := .compiled

.PHONY = all clean %.xclip %.pbcopy %.xclip-src %.xomod $(PREFIX)

all: game.hex

%.bin: %.8o
		./octo/octo $< $@

%.xomod: %.bin
		xomod $<

%.xclip: %.hex
		cat $< | xclip

%.xclip-src: %.8o
		cat $< | xclip

%.pbcopy: %.hex
		cat $< | pbcopy


$(PREFIX):
	mkdir -p $(PREFIX)

$(PREFIX)/tiles.8o: Makefile \
assets/tiles/*
		echo ":org 0xc000" > $@
		./generate-texture.py --map1=0 assets/tileset.png tileset 2 8 >> $@
		./generate-texture.py --map1=3 assets/tiles/highlight_menu.png highlight_menu 2 8 >> $@
		./generate-texture.py --map0=1 assets/tiles/highlight_16.png highlight_16 2 16 >> $@
		./generate-texture.py --map0=2 --map2=1 assets/tiles/splash.png splash 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/tank_front.png robot_tank_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/tank_front_b.png robot_tank_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/engi_front.png robot_engineer_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/engi_front_b.png robot_engineer_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/hacker_front.png robot_hacker_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/hacker_front_b.png robot_hacker_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/repairbot_front.png robot_repairbot_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/repairbot_front_b.png robot_repairbot_front_b 2 16 >> $@

$(PREFIX)/map.8o $(PREFIX)/map_data.8o: Makefile generate-map.py assets/map.json assets/tileset.png
		./generate-map.py assets/map.json 3000 $(PREFIX)

$(PREFIX)/font.8o $(PREFIX)/font_data.8o: Makefile generate-font.py assets/font/5.font
		./generate-font.py assets/font/5.font font 1100 $(PREFIX)

$(PREFIX)/texts.8o $(PREFIX)/texts_data.8o: Makefile assets/en.json generate-text.py
		./generate-text.py $(PREFIX) 1000 assets/en.json \

$(PREFIX)/signature.8o: Makefile ./generate-string.py
		./generate-string.py "DEFINITELY NO FISH HERE ©COWNAMEDSQUIRREL 2018" > $@

$(PREFIX)/sfx.8o: Makefile ./generate-sfx.py
		./generate-sfx.py -c 0 assets/sfx/menu4000.wav menu > $@
		./generate-sfx.py -c 0 assets/sfx/hit4000.wav hit >> $@
		./generate-sfx.py -c 0 assets/sfx/explosion4000.wav explosion >> $@

$(PREFIX)/common.8o: \
Makefile \
$(PREFIX) \
$(PREFIX)/texts.8o \
$(PREFIX)/map.8o \
$(PREFIX)/sfx.8o \
$(PREFIX)/font.8o \
sources/*.8o
		cat sources/globals.8o > $@
		cat $(PREFIX)/texts.8o >> $@
		cat sources/overlay.8o >> $@
		cat $(PREFIX)/map.8o >> $@
		cat sources/objects.8o >> $@
		cat sources/utils.8o >> $@
		cat sources/text.8o >> $@
		cat $(PREFIX)/sfx.8o >> $@ #fixme: REMOVE IT
		cat sources/sfx.8o >> $@
		cat $(PREFIX)/font.8o >> $@

$(PREFIX)/module_8000.8o: \
Makefile \
$(PREFIX) \
$(PREFIX)/common.8o \
sources/*.8o
		echo ": main" > $@
		echo ":org 0x800" >> $@
		cat sources/overworld.8o >> $@
		cat $(PREFIX)/common.8o >> $@
		cat sources/map.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@ #org 0x1000, can be used as guard
		cat $(PREFIX)/font_data.8o >> $@

$(PREFIX)/module_8800.8o: \
Makefile \
$(PREFIX) \
$(PREFIX)/common.8o \
$(PREFIX)/texts_data.8o \
$(PREFIX)/font_data.8o \
$(PREFIX)/tiles.8o \
sources/*.8o
		echo ": main" > $@
		echo ":org 0x800" >> $@
		cat sources/battle.8o >> $@
		cat $(PREFIX)/common.8o >> $@
		cat sources/battle_menu.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@ #org 0x1000, can be used as guard
		cat $(PREFIX)/font_data.8o >> $@
		cat $(PREFIX)/tiles.8o >> $@
		cat sources/battle_object_tiles.8o >> $@


.SECONDARY: $(PREFIX)/module_%.hex: $(PREFIX)/module_%.bin generate-hex.py
$(PREFIX)/module_%.hex: $(PREFIX)/module_%.bin generate-hex.py
		./generate-hex.py -o 1536 -s 2048 -z $< $@ #start at 0x600, size 0x800

game.8o: Makefile \
$(PREFIX) \
$(PREFIX)/common.8o \
$(PREFIX)/texts_data.8o \
$(PREFIX)/tiles.8o \
$(PREFIX)/sfx.8o \
$(PREFIX)/map_data.8o \
$(PREFIX)/module_8000.hex \
$(PREFIX)/module_8800.hex \
$(PREFIX)/signature.8o \
assets/* assets/*/* sources/*.8o
		cat sources/main.8o > $@
		cat $(PREFIX)/common.8o >> $@
		cat sources/math.8o >> $@
		cat sources/tiles.8o >> $@
		cat sources/splash.8o >> $@

		cat $(PREFIX)/map_data.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@ #org 1000
		cat $(PREFIX)/font_data.8o >> $@
		cat $(PREFIX)/tiles.8o >> $@
		cat sources/battle_object_tiles.8o >> $@
		echo ":org 0x8000" >> $@
		cat $(PREFIX)/module_8000.hex >> $@
		echo ":org 0x8800" >> $@
		cat $(PREFIX)/module_8800.hex >> $@
		cat $(PREFIX)/signature.8o >> $@

$(PREFIX)/lz4tile.8o: Makefile ./generate-texture.py assets/screens/nuke.png
		./generate-texture.py assets/tiles/splash.png -c test 2 16 > $@

lz4.8o: \
Makefile \
$(PREFIX)/lz4tile.8o \
sources/*.8o
		cat sources/lz4test.8o > $@
		cat sources/lz4.8o >> $@
		cat sources/tiles.8o >> $@
		echo ":org 0x1234" >> $@
		cat $(PREFIX)/lz4tile.8o >> $@
		echo ":org 0x4000 #buffer" >> $@

lz4.hex: lz4.bin ./generate-hex.py
		./generate-hex.py -l main $< $@

game.hex: game.bin ./generate-hex.py
		./generate-hex.py -l main $< $@

clean:
		rm -f game.bin game.8o game.hex .compiled/*
