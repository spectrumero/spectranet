/* A simple transfer program, allowing a remote host to fill 
 * memory on this machine via a tcp socket opened on port 23.
 * The data should be sent in the following order:
 * byte 0, 1 - start address
 * byte 2, 3 - data length
 * byte 4 onwards - data */
#include <stdio.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <string.h>

main()
{
	int sockfd, rc, connfd;
	unsigned int start, length, rxbytes;
	struct sockaddr_in my_addr;
	char *data;

	/* Clear the screen */
	putchar(0x0C);

	/* Create the socket. At this point, a new socket is allocated
 	   but isn't committed yet to being used for client or server -
	   merely an open socket of type SOCK_STREAM, i.e. TCP */
	sockfd=socket(AF_INET, SOCK_STREAM, 0);
	if(sockfd < 0)
	{
		printf("Could not create socket\n");
		return;
	}

	/* Create the address structure. While the Spectranet doesn't
           pay attention to the sin_family member, you should set it
           to future proof! The only address member we set up is the
	   local port we're going to use. */
	memset(&my_addr, 0, sizeof(my_addr));
	my_addr.sin_family=AF_INET;	/* family - an inet address */
	my_addr.sin_port=htons(23);	/* port to receive data */

	/* Bind the socket to the address we just set up */
	rc=bind(sockfd, &my_addr, sizeof(my_addr));
	if(rc < 0)
	{
		printf("Unable to bind to port 23\n");
		sockclose(sockfd);
		return;
	}

	/* Listen on that socket. */
	rc=listen(sockfd, 1);
	if(rc < 0)
	{
		printf("Unable to listen\n");
		sockclose(sockfd);
		return;
	}

	printf("Waiting for a connection...\n");

	/* accept will block, waiting for a new connection to arrive
	   on the port we associated with the socket with bind().
           When a new connection is established, accept creates a new
           socket for this connection, which should be used for transferring
           the data. The socket that we listened on is still used for
           listening only */
	connfd=accept(sockfd, NULL, NULL);
	if(connfd > 0)
	{
		printf("Accepted connection, receiving data:\n");
		recv(connfd, &start, sizeof(start), 0);

		/* unsigned long / %ld is used to stop >32767 being 
 		   displayed as a negative number */
		printf("Start address: %ld\n", (unsigned long)start);

		recv(connfd, &length, sizeof(length), 0);
		printf("Length       : %ld\n", (unsigned long)length);		

		/* Now point data at the start address. Note that these
                   shenanigans wouldn't work on a system in protected
                   mode, but for a Z80 based system allows us to fill
                   memory at the address specfied */
		data=(char *)start;
		do
		{
			/* receive up to 1024 bytes at a time. */
			rxbytes=recv(connfd, data, 1024, 0);
			length-=rxbytes;	/* count off received so far */
			data+=rxbytes;		/* advance data ptr */
			printf("%ld...", (unsigned long)length);
		} while(length);

		printf("\n");
		printf("Complete\n");
		sockclose(connfd);
		sockclose(sockfd);
	}
	else
	{
		printf("accept failed\n");
	}
}

