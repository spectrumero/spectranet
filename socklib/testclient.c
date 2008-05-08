#include <stdio.h>
#include <input.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <strings.h>
#include "testsocks.h"

void client_bale(int rc);

void testclient()
{
	int sockfd, rc;
	struct sockaddr_in serv_addr;
	struct hostent *he;
	char buf[128];
	char rxbuf[2000];

	printf("Testing client functions\n");

	sockfd=socket(AF_INET, SOCK_STREAM, 0);	
	if(sockfd < 0) 
	{
		client_bale(sockfd);
		return;
	}
	printf("Socket opened: fd=%d\n", sockfd);
	
	printf("gethostbyname...\n");
	he=gethostbyname("spectrum.alioth.net");
	if(!he)
	{
		client_bale(h_errno);
		return;
	}

	serv_addr.sin_port=80;
	serv_addr.sin_addr.s_addr=0xA3D1E6D5;
	printf("Connect...\n");
	rc=connect(sockfd, &serv_addr, sizeof(sockaddr_in));

	if(rc < 0)
	{
		client_bale(rc);
		return;
	}

	printf("send...\n");
	sprintf(buf, "GET / HTTP/1.0\r\n\r\n");
	rc=send(sockfd, buf, strlen(buf), 0);
	if(rc < 0)
	{
		client_bale(rc);
		return;
	}

	printf("recv...\n");
	rc=recv(sockfd, rxbuf, sizeof(rxbuf), 0);
	if(rc < 0)
	{
		client_bale(rc);
		return;
	}
	printf(rxbuf);

	printf("close\n");
	sockclose(sockfd);

	printf("Press a key.\n");
	while(!in_Inkey());	
}

void client_bale(int rc)
{
	printf("Function died with rc=%d\nPress any key to exit.", rc);
	while(!in_Inkey());
}

	
