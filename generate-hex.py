#!/usr/bin/env python2

import argparse

parser = argparse.ArgumentParser(description='Decompile bin to hex')
parser.add_argument('source', help='input file')
parser.add_argument('destination', help='destination')
parser.add_argument('--offset', '-o', type=int, help='start from <offset>')
parser.add_argument('--size', '-s', type=int, help='use first <size> bytes')
parser.add_argument('--label', '-l', type=str, help='label')
parser.add_argument('--strip', '-z', action='store_true', help='strip trailing zeroes')

args = parser.parse_args()
with open(args.source) as fi:
	data = fi.read()

if args.offset is not None:
	data = data[args.offset:]

if args.size is not None:
	data = data[:args.size]

if args.strip:
	data = data.rstrip('\0')

with open(args.destination, 'w') as fo:
	if args.label:
		fo.write(": %s\n" %args.label)

	i = 0
	for x in data:
		fo.write("0x%02x%c" %(ord(x), '\n' if i == 31 else ' '))
		i += 1
		if i == 32:
			i = 0
