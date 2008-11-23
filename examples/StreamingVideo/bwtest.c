#include <stdio.h>
#include <sys/socket.h>
#include <netdb.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
	FILE *stream;
	struct sockaddr_in remoteaddr;
	struct hostent *he;
	int sockfd, bytes, sent;
	char buf[1025];

	if(argc < 2)
	{
		printf("Need a host as the arg\n");
		exit(255);
	}

	he=gethostbyname(argv[1]);
	if(!he)
	{
		perror("gethostbyname");
		exit(255);
	}

	stream=fopen("BWTest.bin", "rb");
	if(!stream)
	{
		perror("fopen");
		exit(255);
	}

	sockfd=socket(AF_INET, SOCK_STREAM, 0);
	if(sockfd < 0)
	{
		perror("socket");
		exit(255);
	}

	printf("Connecting...\n");
	memset(&remoteaddr, 0, sizeof(remoteaddr));
	remoteaddr.sin_family=AF_INET;
	remoteaddr.sin_port=htons(2000);
	memcpy(&(remoteaddr.sin_addr), he->h_addr, he->h_length);
	if(connect(sockfd, (struct sockaddr *)&remoteaddr, sizeof(remoteaddr))
			< 0)
	{
		perror("connect");
		exit(255);
	}

	while((bytes=fread(buf, 1, 1024, stream)) > 0)
	{
		while((sent=write(sockfd, buf, bytes)) < bytes)
		{
			bytes-=sent;
		}
	}
	close(sockfd);
	fclose(stream);
	return 0;
}

