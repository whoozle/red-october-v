#!/usr/bin/env python2

import argparse
import json
import os.path

parser = argparse.ArgumentParser(description='generate code for tmx map')
parser.add_argument('source', help='input file')
parser.add_argument('address', help='address to load from')
parser.add_argument('prefix', help='destination directory')

args = parser.parse_args()
addr = int(args.address, 16)

def update_layer(data, layer):
	lw, lh = layer['width'], layer['height']
	lx, ly = layer['x'], layer['y']
	ldata = layer['data']

	for y in xrange(lh):
		for x in xrange(lw):
			if x + lx < 0 or x + lx >= width or y + ly < 0 or y + ly >= height:
				continue

			tid = ldata[y * lw + x]
			offset = (y + ly) * width + x + lx
			if data[offset] > 0:
				raise Exception('duplicate tile at layer %s @ %d, %d' %(layer['name'], x, y))
			if tid < 0 or tid > 255:
				print "WARNING: layer %s @ %d,%d, tile id: 0x%08x is out of range" %(layer['name'], x, y, tid)
				tid = 0
			data[offset] = tid

map_data_path = os.path.join(args.prefix, 'map_data.8o')
map_header_path = os.path.join(args.prefix, 'map.8o')
objects = {}

with open(args.source) as fi, open(map_data_path, 'w') as fmap_data, open(map_header_path, 'w') as fmap_header:
	map_json = json.load(fi)
	width, height = map_json['width'], map_json['height']
	screen_width, screen_height = 128, 64
	hscreens, vscreens = (width + 15) / 16, (height + 7) / 8 #how many vertical/horizontal screens we have
	size = width * height

	fmap_header.write(":const map_data_hi 0x%02x\n" %(addr >> 8))
	fmap_header.write(":const map_data_lo 0x%02x\n" %(addr & 0xff))
	fmap_header.write(':const map_width %d\n' %width)
	fmap_header.write(':const map_height %d\n' %height)
	fmap_header.write(':const map_screens %d\n' %(hscreens * vscreens))

	data = [0 for i in xrange(size)]
	walls_data = [0 for i in xrange(size)]

	for layer in map_json['layers']:
		if 'data' in layer:
			if layer['name'] == 'Walls':
				update_layer(walls_data, layer)
				continue

			if not layer['visible']:
				continue

			update_layer(data, layer)
		elif 'objects' in layer:
			lobjs = layer['objects']
			object_types = {}
			object_type_index = 1
			for lobj in lobjs:
				name, type_name, x, y, w, h = lobj['name'], lobj['type'], int(lobj['x']), int(lobj['y']), int(lobj['width']), int(lobj['height'])
				sx, sy = x / screen_width, y / screen_height #screen coordinates
				screen_id = sy * hscreens + sx
				# print 'screen_id', screen_id, name, x, y
				screen_objects = objects.setdefault(screen_id, [])

				if not type_name in object_types:
					object_types[type_name] = object_type_index
					fmap_header.write(':const map_object_type_%s 0x%02x\n' %(type_name, object_type_index))
					object_type_index += 1

				obj_x = x - sx * screen_width
				obj_y = y - sy * screen_height - h

				obj_properties = lobj['properties']

				if type_name == "door":
					door_x = 0
					door_y = 0
					door_screen = 0
					for door_prop in obj_properties:
						prop_name = door_prop['name']
						prop_value = door_prop['value']
						if prop_name == 'exit_door_x':
							door_x = prop_value
						if prop_name == 'exit_door_y':
							door_y = prop_value
						if prop_name == 'screen':
							door_screen = prop_value
					screen_objects += (object_types[type_name], obj_x, obj_y, door_screen, door_x, door_y)
				elif type_name == "battle":
					battle_id = 0
					for battle_prop in obj_properties:
						prop_name = battle_prop['name']
						if prop_name == 'value':
							battle_id = battle_prop['value']
					print "Parse battle", battle_id
					screen_objects += (object_types[type_name], obj_x, obj_y, battle_id)
				else:
					powerup_value = 0
					for powerup_prop in obj_properties:
						prop_name = powerup_prop['name']
						if prop_name == 'power':
							powerup_value = powerup_prop['value']
					screen_objects += (object_types[type_name], obj_x, obj_y, powerup_value)
		else:
			print 'unhandled layer %s' %layer

	indices = {}
	object_types = {}
	object_list_data = {}
	object_init_data = {}
	object_collide_data = {}

	fmap_data.write(":org 0x%04x\n" %addr)
	fmap_data.write(': map_data\n')
	for y in xrange(height):
		row = []
		for x in xrange(width):
			row.append('0x%02x' %data[y * width + x])
		fmap_data.write(' '.join(row) + '\n')

	walls_data_packed = []
	for idx in xrange(0, len(walls_data), 8):
		tiles = walls_data[idx: idx + 8]
		value = 0
		for idx, tid in enumerate(tiles):
			value |= (0x80 >> idx) if tid > 0 else 0
		walls_data_packed.append('0x%02x' %value)

	fmap_data.write(":org 0x%04x\n" %((addr + width * height + 0xff) / 0x100 * 0x100))
	fmap_data.write(': map_walls_data\n%s\n' % ' '.join(walls_data_packed))

	fmap_data.write(': map_object_data_screen_empty 0\n')
	for screen_id, object_data in sorted(objects.iteritems()):
		fmap_data.write(': map_object_data_screen_%d\n' %screen_id)
		fmap_data.write('%s\n' %(" ".join(map(hex, object_data + [0]))))

	fmap_data.write(': map_object_data\n')
	for screen_id in xrange(hscreens * vscreens):
		if screen_id in objects:
			fmap_data.write('offset map_object_data_screen_%d\n' %screen_id)
		else:
			fmap_data.write('offset map_object_data_screen_empty\n')
