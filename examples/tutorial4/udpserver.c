/* A simple UDP server - this goes with the following tutorial:
 * http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_4
 *
 * Compile with the command:
 * zcc +zx -vn -O2 -o udpserver.bin udpserver.c -lndos -llibsocket */

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>

main()
{
	int sockfd, rc, addrsz;
	struct sockaddr_in their_addr;	/* For sendto and recvfrom */
	struct sockaddr_in my_addr;	/* For when we call bind */
	char sendbuf[128];		/* A buffer with data to send */
	char recvbuf[128];		/* A buffer for receiving data */

	/* Create the socket as normal. */
	sockfd=socket(AF_INET, SOCK_DGRAM, 0);
	if(sockfd < 0)
	{
		printk("Could not create socket\n");
		return;
	}

	/* Now set up the local address (i.e. family and port) for this
 	   socket. */
	my_addr.sin_family=AF_INET;
	my_addr.sin_port=2000;		/* UDP port 2000 */
	rc=bind(sockfd, &my_addr, sizeof(my_addr));
	if(rc < 0)
	{
		printk("Could not bind socket to a port\n");
		return;
	}
	printk("Listening on port 2000. Send 'x' to end the program.\n");

	while(1)
	{
		/* Wait for a datagram to come in, print what it contains, then
		   send a message back */
		rc=recvfrom(sockfd, recvbuf, sizeof(recvbuf)-1, 0, 
			    &their_addr, &addrsz);
		if(rc < 0)
		{
			printk("recv failed\n");
			break;
		}

		/* If the first byte of what we're sent is 'x', 
		   we'll just exit */
		if(*recvbuf == 'x')
			break;

		/* since we're going to print the message, make sure it has a
		   null at the end, to make it a valid C string. 'rc' contains
		   the number of bytes received */
		*(recvbuf + rc)=0;

		/* Print the string, then send a message back. */
		printk("Received: %s\n", recvbuf);

		sprintf(sendbuf, "You sent me %d bytes\n", rc);
		
		/* Note how we use the struct sockaddr_in their_addr. This will
		   have been filled by the prior call to 'recvfrom' with the
		   address and port used by the remote host. */
		rc=sendto(sockfd, sendbuf, strlen(sendbuf), 0,
			  &their_addr, addrsz);
		if(rc < 0)
		{
			printk("sendto failed\n");
			break;
		}
	}
	sockclose(sockfd);
}

