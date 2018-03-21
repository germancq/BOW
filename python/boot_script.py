# Design: boot_script.py
# Description: 
# Author: German Cano Quiveu <germancq@dte.us.es>
# Copyright Universidad de Sevilla, Spain

import sys
import binascii
import collections

elf_signature = binascii.unhexlify(b'7F454C46') 
PH_info = collections.namedtuple('PH_info','offset sz vaddr')

def from_bytes (data, big_endian = True):
    if isinstance(data, str):
        data = bytearray(data)
    if big_endian:
        data = reversed(data)
    num = 0
    for offset, byte in enumerate(data):
        num += byte << (offset * 8)
    return num

def compare_elf_signature(i_file):
	i_file.seek(0)
	i_elf = i_file.read(4)
	if i_elf == elf_signature :
		return True
	else:
		print("Not elf file")
		sys.exit(2)
		
def getPHoffset(i_file):
	i_file.seek(28)
	i_ph_offset = i_file.read(4)
	return from_bytes(i_ph_offset)

def getNumberPH(i_file):
	i_file.seek(44)
	numPH = i_file.read(2)
	return from_bytes(numPH)

def getDataPH(i_file,offset,index):
	#Program Header size is 32 bytes
	startPH = offset + (32*index)
	#offset of the segment in the file image
	i_file.seek(startPH + 4)
	ph_offset = i_file.read(4)
	#size in bytes in the file image
	i_file.seek(startPH + 16)
	ph_filesz = i_file.read(4)
	#virtual address
	i_file.seek(startPH + 8)
	ph_vaddr = i_file.read(4)
	return PH_info(offset = from_bytes(ph_offset),sz = from_bytes(ph_filesz), vaddr = from_bytes(ph_vaddr))

def writePH(i_file,o_file,info_ph):	
	if(o_file.tell() < info_ph.offset):
		for x in range (o_file.tell(),info_ph.vaddr):
			o_file.write(b"\x00")
	i_file.seek(info_ph.offset)
	o_file.seek(info_ph.vaddr)
	o_file.write(i_file.read(info_ph.sz))

def alignTo512(o_file):
	sz = o_file.tell()#current position
	mod512 = sz % 512
	for x in range (0, 512-mod512):
		o_file.write(b"\x00")
	print(o_file.tell()/512)
		

def main():		
	with open(sys.argv[1],"rb") as input_file:
		with open(sys.argv[2], "wb") as output_file:
			compare_elf_signature(input_file)
			program_header_offset = getPHoffset(input_file)
			program_header_number = getNumberPH(input_file)
			for k in range (0, program_header_number):
				info = getDataPH(input_file,program_header_offset,k)
				writePH(input_file,output_file,info)
			alignTo512(output_file)		


if __name__ == "__main__":
    main()
