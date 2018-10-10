#!/usr/bin/env python2

import argparse
import png

parser = argparse.ArgumentParser(description='Compile font.')
parser.add_argument('source', help='input file')
parser.add_argument('name', help='name')
parser.add_argument('planes', type=int, help='planes (1/2)')
parser.add_argument('tile-size', type=int, help='tile size (8/16)')
parser.add_argument('--compress', '-c', action='store_true', help='compress bitmap with lz4 algorithm')
parser.add_argument('--algorithm', '-A', type=str, help='select algo', default='lz4')
parser.add_argument('--map0', type=int, help='map bg color to chip8 color')
parser.add_argument('--map1', type=int, help='map palette color 1 to chip8 color')
parser.add_argument('--map2', type=int, help='map palette color 2 to chip8 color')
parser.add_argument('--map3', type=int, help='map palette color 3 to chip8 color')
args = parser.parse_args()

tex = png.Reader(args.source)
w, h, pixels, metadata = tex.read_flat()
tile_size = getattr(args, 'tile-size')
if tile_size != 8 and tile_size != 16:
	raise Exception("invalid tile size %d" %tile_size)
tw, th = tile_size, tile_size

def label(name):
	return ": tile_%s_%s" %(args.name, name)

nx = (w + tw - 1) / tw
ny = (h + th - 1) / th

replace_color = [0, 1, 2, 3]

def replace(c1, c2):
	old = replace_color[c1]
	replace_color[c1] = c2
	replace_color[c2] = old

if args.map0 is not None:
	replace(0, args.map0)
if args.map1 is not None:
	replace(1, args.map1)
if args.map2 is not None:
	replace(2, args.map2)
if args.map3 is not None:
	replace(3, args.map3)

def get_pixel(x, y, plane):
	if x < 0 or x >= w:
		return 0
	if y < 0 or y >= h:
		return 0

	value = replace_color[pixels[y * w + x]]
	bit = 1 << plane
	return 1 if value & bit else 0

def huffman(data):
	class Node(object):
		def __init__(self, symbol, weight):
			self.symbol, self.weight = symbol, weight

		def __repr__(self):
			return "Node(%d, %d)" %(self.symbol, self.weight)

		def generate(self, prefix, result):
			result(prefix, self.symbol)

	class CompositeNode(object):
		def __init__(self, zero, one):
			self.zero, self.one = zero, one
			self.weight = zero.weight + one.weight

		def __repr__(self):
			return "CompositeNode([%s, %s], %d)" %(repr(self.zero), repr(self.one), self.weight)

		def generate(self, prefix, result):
			self.zero.generate(prefix + '0', result)
			self.one.generate(prefix + '1', result)

	tokens = []
	for b in data:
		for i in xrange(4):
			tokens.append((b >> (6 - i * 2)) & 3)
	stats = { 0: 0, 1: 0, 2: 0, 3: 0 }
	for b in tokens:
		stats[b] += 1

	nodes = []
	for s, w in stats.iteritems():
		nodes.append(Node(s, w))
	while len(nodes) > 1:
		nodes.sort(key = lambda x: x.weight)
		z, o = nodes.pop(0), nodes.pop(0)
		nodes.append(CompositeNode(z, o))

	tree = {}
	def result(bits, symbol):
		print "# symbol %d -> %s" %(symbol, bits)
		tree[symbol] = bits

	nodes[0].generate('', result)
	text = ''
	for t in tokens:
		text += tree[t]

	n = len(text)
	r = n % 8
	if r:
		for i in xrange(8 - r):
			text += '0'
	n = len(text)

	data = bytearray()
	for i in xrange(0, n, 8):
		data.append(int(text[i: i + 8], 2))

	return data


if args.compress:
	print label("cdata")
	packed_data = bytearray()
	for ty in xrange(0, ny):
		basey = ty * th
		for tx in xrange(0, nx):
			basex = tx * tw
			for plane in xrange(0, args.planes):
				for y in xrange(0, th):
					for x in xrange(0, tw / 8):
						byte = 0
						for bit in xrange(0, 8):
							byte |= get_pixel(basex + x * 8 + bit, basey + y, plane) << (7 - bit)
						packed_data.append(byte)
	if args.algorithm == "lz4":
		from lz4.block import compress
		compressed_data = bytearray(compress(packed_data, mode='high_compression', compression=12, store_size=False))
	elif args.algorithm == "huffman":
		compressed_data = huffman(packed_data)

	print "#compressed size: %d of %d\n" %(len(compressed_data), len(packed_data))
	print " ".join(map(lambda x: "0x%02x" %x, compressed_data))

else:
	print label("data"),
	for ty in xrange(0, ny):
		basey = ty * th
		if nx > 1 or ny > 1:
			print "\n" + label("row_%d" %ty)
		for tx in xrange(0, nx):
			basex = tx * tw
			if nx > 1 or ny > 1:
				print "\n" + label("%d_%d" %(ty, tx))
			for plane in xrange(0, args.planes):
				for y in xrange(0, th):
					for x in xrange(0, tw / 8):
						byte = 0
						for bit in xrange(0, 8):
							byte |= get_pixel(basex + x * 8 + bit, basey + y, plane) << (7 - bit)
						print "0x%02x" %byte ,
