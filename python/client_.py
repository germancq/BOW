# Design: client_.py
# Description:
# Author: German Cano Quiveu <germancq@dte.us.es>
# Copyright Universidad de Sevilla, Spain

import requests
import os
import math
import sys
import base64
import time


url = 'http://192.168.1.40:3000/data'
chunk_len = 512
json = {}
data_rd =''
error_packets = []

def get_file_size(input_file):
	return os.fstat(input_file.fileno()).st_size


def send(n_block, total_blocks,input_file, total_bytes,encodeString):
	#print('send data')
	startTime = time.time()*1000

	#print(encodeString)
	json = {'n_block':n_block,
		'total_blocks':total_blocks,
		'total_bytes':total_bytes,
		'data':encodeString}
	r = requests.post(url, data = json)

	endTime = time.time()*1000
	print('packet ',n_block,' of ',total_blocks)
	#print (r.text)
	print(r.status_code)
	return r.status_code

def maintask(filename):
	del error_packets[:]
	with open(filename,"rb") as input_file:
		file_size = get_file_size(input_file)
		#print(file_size)
		count_loop = math.ceil(file_size/chunk_len)
		print('total packets:',count_loop)
		last_loop_bytes = chunk_len - ((count_loop * chunk_len) - file_size)
		#print(last_loop_bytes)
		input_file.seek(0)
		for k in range (0, count_loop):
			rd_bytes = chunk_len
			if k == (count_loop - 1) :
				rd_bytes = last_loop_bytes

			encodeString = base64.b64encode(input_file.read(rd_bytes))
			code_status = 404
			while code_status == 404 :
				code_status = send(k,count_loop,input_file,rd_bytes,encodeString)
				if code_status == 200:
					break
				else :
					print('ERROR')
					error_packets.append(k)

		print('Error Packets are:')
		print(error_packets)

def main():
	maintask(sys.argv[1])

if __name__ == "__main__":
    main()
