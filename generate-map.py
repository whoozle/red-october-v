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
			for lobj in lobjs:
				name, x, y, w, h = lobj['name'], int(lobj['x']), int(lobj['y']), int(lobj['width']), int(lobj['height'])
				sx, sy = x / screen_width, y / screen_height #screen coordinates
				screen_id = sy * hscreens + sx
				#print 'screen_id', screen_id, name, x, y
				screen_objects = objects.setdefault(screen_id, [])
				screen_objects.append((name, x - sx * screen_width, y - sy * screen_height, w, h))
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
