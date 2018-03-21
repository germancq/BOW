# Design: client_.py
# Description: 
# Author: German Cano Quiveu <germancq@dte.us.es>
# Copyright Universidad de Sevilla, Spain

import requests
import os
import math
import sys
import base64


url = 'http://192.168.2.8:3000/data'
chunk_len = 512
json = {}
data_rd =''

def get_file_size(input_file):
	return os.fstat(input_file.fileno()).st_size


def send(n_block, total_blocks,input_file, total_bytes):
	#print('send data')
	encodeString = base64.b64encode(input_file.read(total_bytes))
	#print(encodeString)
	json = {'n_block':n_block,
		'total_blocks':total_blocks,
		'total_bytes':total_bytes,
		'data':encodeString}
	r = requests.post(url, data = json)
	#print(r.status_code)


def main():		
	with open(sys.argv[1],"rb") as input_file:
		file_size = get_file_size(input_file)
		#print(file_size)
		count_loop = math.ceil(file_size/chunk_len)
		#print(count_loop)
		last_loop_bytes = chunk_len - ((count_loop * chunk_len) - file_size)
		#print(last_loop_bytes)
		input_file.seek(0)			
		for k in range (0, count_loop):
			rd_bytes = chunk_len
			if k == (count_loop - 1) :
				rd_bytes = last_loop_bytes
			send(k,count_loop,input_file,rd_bytes)
			

if __name__ == "__main__":
    main()
