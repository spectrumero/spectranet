/*
;The MIT License
;
;Copyright (c) 2011 Dylan Smith
;
;Permission is hereby granted, free of charge, to any person obtaining a copy
;of this software and associated documentation files (the "Software"), to deal
;in the Software without restriction, including without limitation the rights
;to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;copies of the Software, and to permit persons to whom the Software is
;furnished to do so, subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in
;all copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
;THE SOFTWARE.
*/

/* Configuration server for initial Spectranet setup.
 * It is very simple, it merely sends a MAC address and hostname with
 * each connection, then disconnects.
 * Listens on tcp/2001
 *
 * During initial configuration the Spectrum has a hard-coded MAC
 * address and IP for the purposes of querying this server. */

#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#define DATASZ	24

void server(char *file, int port);
void getdata(char *file, char *data);

int main(int argc, char **argv) {
	if(argc < 2) {
		fprintf(stderr, "Usage: %s <serialfile>\n", argv[0]);
		exit(-1);
	}
	server(argv[1], 2001);
	return 0;
}

void server(char *file, int port) {
	int sockfd, connfd, bytes;
	struct sockaddr_in my_addr;
	char cfgdata[DATASZ];

	sockfd=socket(AF_INET, SOCK_STREAM, 0);
	if(sockfd<0) {
		perror("socket");
		exit(-1);
	}

	memset(&my_addr, 0, sizeof(my_addr));
	my_addr.sin_family=AF_INET;
	my_addr.sin_port=htons(port);
	if(bind(sockfd, (struct sockaddr *)&my_addr, sizeof(my_addr)) < 0) {
		perror("bind");
		exit(-1);
	}

	if(listen(sockfd, 1) < 0) {
		perror("listen");
		exit(-1);
	}

	while((connfd=accept(sockfd, NULL, NULL)) > 0) {
		getdata(file, cfgdata);
		bytes=send(connfd, cfgdata, DATASZ, 0);
		if(bytes < DATASZ) {
			fprintf(stderr, 
			"warning: sent fewer bytes than expected");
		}
		close(connfd);
	}
}

void getdata(char *file, char *data) {
	FILE *stream;
	long mac;
	int serno;

	if((stream=fopen(file, "rb")) != NULL) {
		fscanf(stream, "%d", &serno);
		fclose(stream);
		if((stream=fopen(file, "wb")) != NULL) {
			fprintf(stream, "%d", serno+1);
			fclose(stream);
		} else {
			perror("writing serial number");
			exit(-1);
		}
	} else {
		perror("reading serial number");
		exit(-1);
	}

	mac=random();

	data[0]=0x00;
	data[1]=0xAA;
	data[2]=mac & 0xFF;
	data[3]=(mac >> 8) & 0xFF;
	data[4]=(mac >> 16) & 0xFF;
	data[5]=(mac >> 24) & 0xFF;
	sprintf(&data[6], "spectranet%d", serno);
}


