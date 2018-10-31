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
		./generate-texture.py --map0=2 --map2=1 assets/tiles/splash3.png splash 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/tank_front.png robot_tank_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/tank_front_b.png robot_tank_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/engi_front.png robot_engineer_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/engi_front_b.png robot_engineer_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/hacker_front.png robot_hacker_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/hacker_front_b.png robot_hacker_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/repairbot_front.png robot_repairbot_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/repairbot_front_b.png robot_repairbot_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/beefcake_front.png robot_beefcake_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/beefcake_front_b.png robot_beefcake_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/ninja_front.png robot_ninja_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/ninja_front_b.png robot_ninja_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/smartkid_front.png robot_smartkid_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/smartkid_front_b.png robot_smartkid_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/miner_front.png robot_miner_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/miner_front_b.png robot_miner_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/bomb.png robot_bomb_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/bomb_b.png robot_bomb_front_b 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/dead_robot.png dead_robot 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/attack_shot.png attack_shot 2 8 >> $@
		./generate-texture.py --map1=0 assets/tiles/attack_engi.png attack_engi 2 8 >> $@
		./generate-texture.py --map1=0 assets/tiles/attack_repair.png attack_repair 2 8 >> $@
		./generate-texture.py --map1=0 assets/tiles/attack_hack.png attack_hack 2 8 >> $@
		./generate-texture.py --map2=1 assets/tiles/hp_bar.png hp_bar 2 8 >> $@
		./generate-texture.py --map1=0 assets/tiles/hero_front.png player_front 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/hero_left.png player_left 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/hero_right.png player_right 2 16 >> $@
		./generate-texture.py --map1=0 assets/tiles/hero_back.png player_back 2 16 >> $@
		./generate-texture.py --map2=1 assets/tiles/power_up.png power_up 2 16 >> $@
		./generate-texture.py --map1=3 assets/tiles/attack.png attack 2 16 >> $@
		./generate-texture.py assets/tiles/attack_highlight.png attack_highlight 2 16 >> $@
		./generate-texture.py --map1=0 assets/screens/crushed.png crushed 2 16 >> $@
		./generate-texture.py --map1=0 assets/screens/nuke.png nuke 2 16 >> $@
		./generate-texture.py --map1=0 assets/screens/space.png space 2 16 >> $@
		./generate-texture.py --map1=0 assets/screens/submarine.png submarine 2 16 >> $@
		./generate-texture.py --map1=0 assets/screens/underthesea.png underthesea 2 16 >> $@

$(PREFIX)/map.8o $(PREFIX)/map_data.8o: Makefile generate-map.py assets/map.json assets/tileset.png
		./generate-map.py assets/map.json 3000 $(PREFIX)

$(PREFIX)/font.8o $(PREFIX)/font_data.8o: Makefile generate-font.py assets/font/5.font
		./generate-font.py assets/font/5.font font 1400 $(PREFIX)

$(PREFIX)/texts.8o $(PREFIX)/texts_data.8o: Makefile assets/en.json generate-text.py
		./generate-text.py $(PREFIX) 1000 assets/en.json \

$(PREFIX)/signature.8o: Makefile ./generate-string.py
		./generate-string.py -r 65000 "DEFINITELY NO FISH HERE ©COWNAMEDSQUIRREL 2018" > $@

$(PREFIX)/sfx.8o: Makefile ./generate-sfx.py assets/sfx/*.wav
		echo ":org 0x5800" > $@
		./generate-sfx.py -c 0 assets/sfx/menu4000.wav menu >> $@
		./generate-sfx.py -c 0 assets/sfx/hit4000.wav hit >> $@
		./generate-sfx.py -c 0 assets/sfx/explosion4000.wav explosion >> $@
		./generate-sfx.py -c 0 assets/sfx/shoot4000.wav shoot >> $@
		./generate-sfx.py -c 0 assets/sfx/powerup4000.wav powerup >> $@
		./generate-sfx.py -c 0 assets/sfx/move4000.wav move >> $@

$(PREFIX)/common.8o: \
Makefile \
$(PREFIX) \
$(PREFIX)/texts.8o \
$(PREFIX)/map.8o \
$(PREFIX)/font.8o \
sources/*.8o
		cat sources/globals.8o > $@
		cat $(PREFIX)/texts.8o >> $@
		cat sources/overlay.8o >> $@
		cat $(PREFIX)/map.8o >> $@
		cat sources/objects.8o >> $@
		cat sources/utils.8o >> $@
		cat sources/text.8o >> $@
		cat sources/sfx.8o >> $@
		cat $(PREFIX)/font.8o >> $@

$(PREFIX)/module_main.8o: \
Makefile \
$(PREFIX)
		echo ": main" > $@
		echo "hires" >> $@
		echo "plane 3" >> $@
		echo "clear" >> $@
		echo "jump 0x800" >> $@
		echo ":org 0x800" >> $@


$(PREFIX)/module_8000.8o: \
Makefile \
$(PREFIX) \
$(PREFIX)/common.8o \
$(PREFIX)/module_main.8o \
$(PREFIX)/font_data.8o \
$(PREFIX)/texts_data.8o \
$(PREFIX)/tiles.8o \
$(PREFIX)/map_data.8o \
sources/*.8o
		cat $(PREFIX)/common.8o > $@
		cat $(PREFIX)/module_main.8o >> $@
		cat sources/overworld.8o >> $@
		cat sources/saveload.8o >> $@
		cat sources/map.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@ #org 0x1000, can be used as guard
		cat $(PREFIX)/font_data.8o >> $@
		cat $(PREFIX)/tiles.8o >> $@
		cat $(PREFIX)/map_data.8o >> $@
		cat $(PREFIX)/sfx.8o >> $@
		cat sources/sfx_table.8o >> $@

$(PREFIX)/module_8800.8o: \
Makefile \
$(PREFIX) \
$(PREFIX)/common.8o \
$(PREFIX)/module_main.8o \
$(PREFIX)/texts_data.8o \
$(PREFIX)/font_data.8o \
$(PREFIX)/tiles.8o \
$(PREFIX)/sfx.8o \
sources/*.8o
		cat $(PREFIX)/common.8o > $@
		cat $(PREFIX)/module_main.8o >> $@
		cat sources/battle.8o >> $@
		cat sources/math.8o >> $@
		cat sources/battle_menu.8o >> $@
		cat sources/battle_menu2.8o >> $@
		cat sources/battle_target.8o >> $@
		cat sources/battle_objects.8o >> $@
		cat sources/saveload.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@ #org 0x1000, can be used as guard
		cat $(PREFIX)/font_data.8o >> $@
		cat $(PREFIX)/tiles.8o >> $@
		cat sources/battle_data.8o >> $@
		cat $(PREFIX)/sfx.8o >> $@
		cat sources/sfx_table.8o >> $@

$(PREFIX)/module_9000.8o: \
Makefile \
$(PREFIX) \
$(PREFIX)/common.8o \
$(PREFIX)/module_main.8o \
$(PREFIX)/texts_data.8o \
$(PREFIX)/font_data.8o \
$(PREFIX)/tiles.8o \
$(PREFIX)/sfx.8o \
sources/*.8o
		cat $(PREFIX)/common.8o > $@
		cat $(PREFIX)/module_main.8o >> $@
		cat sources/comix.8o >> $@
		cat sources/tiles.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@ #org 0x1000, can be used as guard
		cat $(PREFIX)/font_data.8o >> $@
		cat $(PREFIX)/tiles.8o >> $@
		cat $(PREFIX)/sfx.8o >> $@
		cat sources/sfx_table.8o >> $@


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
$(PREFIX)/module_9000.hex \
$(PREFIX)/signature.8o \
assets/* assets/*/* sources/*.8o
		cat $(PREFIX)/common.8o > $@
		cat sources/main.8o >> $@
		cat sources/saveload.8o >> $@
		cat sources/math.8o >> $@
		cat sources/tiles.8o >> $@

		cat $(PREFIX)/map_data.8o >> $@
		cat $(PREFIX)/sfx.8o >> $@
		cat sources/sfx_table.8o >> $@
		cat $(PREFIX)/texts_data.8o >> $@ #org 1000
		cat $(PREFIX)/font_data.8o >> $@
		cat $(PREFIX)/tiles.8o >> $@
		cat sources/battle_data.8o >> $@
		echo ":org 0x8000" >> $@
		cat $(PREFIX)/module_8000.hex >> $@
		echo ":org 0x8800" >> $@
		cat $(PREFIX)/module_8800.hex >> $@
		echo ":org 0x9000" >> $@
		cat $(PREFIX)/module_9000.hex >> $@
		cat $(PREFIX)/signature.8o >> $@

$(PREFIX)/lz4tile.8o: Makefile ./generate-texture.py assets/tiles/splash.png
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
