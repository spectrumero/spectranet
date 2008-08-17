/* A simple UDP client - this goes with the following tutorial:
 * http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_4
 *
 * Compile with the command:
 * zcc +zx -vn -O2 -o udpclient.bin udpclient.c -lndos -llibsocket */

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>	/* for gethostbyname() */

/* set this to whatever the IP address or DNS name of the remote host you
 * want to connect to should be. */
#define REMOTE_HOST	"172.16.0.2"

main()
{
	int sockfd, rc, addrsz;
	struct sockaddr_in their_addr;	/* For sendto and recvfrom */
	char sendbuf[128];		/* A buffer with data to send */
	char recvbuf[128];		/* A buffer for receiving data */
	struct hostent *he;
	char *greet="Spectrum UDP client\n";

	/* First, look up the remote host. */
	he=gethostbyname(REMOTE_HOST);
	if(!he)
	{
		printk("gethostbyname() failed\n");
		return;
	}

	/* Create the socket as normal. */
	sockfd=socket(AF_INET, SOCK_DGRAM, 0);
	if(sockfd < 0)
	{
			return;
		printk("Could not create socket\n");
		return;
	}

	memset(&their_addr, 0, sizeof(their_addr));
	their_addr.sin_family=AF_INET;		/* Family - internet socket */
	their_addr.sin_addr.s_addr=he->h_addr;	/* IP address */
	their_addr.sin_port=htons(2000);	/* Port 2000 */

	/* Send a message to say 'hello' */
	printk("Sending a greeting to the UDP server...\n");
	rc=sendto(sockfd, greet, strlen(greet), 0,
		  &their_addr, sizeof(their_addr));
	if(rc < 0)
	{
		printk("Initial send() failed!\n");
		sockclose(sockfd);
		return;
	}

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

