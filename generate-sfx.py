#!/usr/bin/env python2

from __future__ import print_function

import argparse
import wave
import struct
import sys

parser = argparse.ArgumentParser(description='Convert audio.')
parser.add_argument('source', help='input file')
parser.add_argument('name', help='name')
parser.add_argument('-c', '--cutoff', help = 'cutoff value', default=0.1, type=float)
parser.add_argument('-o', '--output', help = 'dump audio as wav file')
args = parser.parse_args()

wav = wave.open(args.source)
n = wav.getnframes()
if wav.getsampwidth() != 2:
	raise Exception("invalid sample width")
if wav.getnchannels() != 1:
	raise Exception("only mono supported")
if wav.getframerate() != 4000:
	raise Exception("invalid sample rate %d, sox -S %s -r 4000 -b 16 <output>" %(wav.getframerate(), args.source))

frames = wav.readframes(n)

wavdata = bytes()
data = []

peak = 0

offset = 0
for i in xrange(0, n):
	value, = struct.unpack('<h', frames[offset: offset + 2]) if offset < len(frames) else (0,)
	offset += 2
	if value > peak:
		peak = value
	elif value < -peak:
		peak = -value

offset = 0
size = 0
bit, byte = 0, 0
cutoff = args.cutoff

for i in xrange(0, n):
	buf = []

	value, = struct.unpack('<h', frames[offset: offset + 2]) if offset < len(frames) else (0,)
	offset += 2

	x = 1.0 * value / peak
	assert x >= -1 and x <= 1

	out = x >= cutoff

	if out:
		byte |= (0x80 >> bit)
		y = 1
		wavdata += struct.pack('<h', 16384)
	else:
		y = -1
		wavdata += struct.pack('<h', -16384)

	bit += 1
	if bit == 8:
		data.append(byte)
		bit = 0
		byte = 0
		size += 1

if size % 16:
	rem = 16 - (size % 16)
	for i in xrange(0, rem):
		size += 1
		data.append(0)

source, index = '', ''
source += ": audio_%s\n" %args.name

for idx, byte in enumerate(data):
	mask = idx & 0x0f
	if mask == 0:
		source += '\t'
	source += '0x%02x' %byte
	if mask == 15:
		source += '\n'
	else:
		source += ' '

size /= 16 #loop count
print (":const audio_%s_size %d\n" %(args.name, size))
print ("%s\n"  %source)

if args.output:
	out = wave.open(args.output, 'w')
	out.setnchannels(1)
	out.setsampwidth(2)
	out.setframerate(wav.getframerate())
	out.setnframes(len(wavdata) / 2)
	out.writeframes(wavdata)
	out.close() #no __exit__
