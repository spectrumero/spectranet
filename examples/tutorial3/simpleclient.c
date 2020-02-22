/* A simple TCP server - this goes along with the following:
 *  http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_3 */

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>		/* socket, connect, send, recv etc. */
#include <sys/types.h>		/* types, such as socklen_t */
#include <netdb.h>		/* gethostbyname */

main()
{
	int sockfd, bytes;
	struct sockaddr_in remoteaddr;
	char *txdata="GET / HTTP/1.0\r\n\r\n";
	char rxdata[1024];
	struct hostent *he;

	/* clear the screen */
	putchar(0x0C);

	/* Look up the host that we want to connect to. */
	/* Note that hostent pointer is statically allocated, don't try
	   to free it! */
	printk("Looking up spectrum.alioth.net...\n");
	he=gethostbyname("spectrum.alioth.net");
	if(!he)
	{
		printk("Failed to look up remote host\n");
		return;
	}
	

        /* Create the socket */
        /* The first argument, AF_INET is the family. The Spectranet only
           supports AF_INET at present. SOCK_STREAM in this context is
           for a TCP connection. */
	sockfd=socket(AF_INET, SOCK_STREAM, 0);
	if(sockfd < 0)
	{
		printk("Couldn't open the socket - rc=%d\n",sockfd);
		return;
	}

	/* Set up the sockaddr_in structure. Note that once we've
	   copied the address, we don't have to worry about gethostbyname
           overwriting the static struct hostent that it keeps */
	printk("Connecting...\n");
	remoteaddr.sin_port=htons(80);		/* port 80 - http */
	remoteaddr.sin_addr.s_addr=he->h_addr;	/* ip address */
	if(connect(sockfd, &remoteaddr, sizeof(struct sockaddr_in)) < 0)
	{
		sockclose(sockfd);
		printk("Connect failed!\n");
		return;
	}

	/* Send 'GET / HTTP/1.0\r\n\r\n' to the remote host */
	bytes=send(sockfd, txdata, strlen(txdata), 0);
	if(bytes < 0)
	{
		printk("Send failed\n");
		sockclose(sockfd);
		return;
	}

	/* Get the response - use 1 byte less than the buffer so
           we can guarantee to be able to null terminate it for printing */
	bytes=recv(sockfd, rxdata, sizeof(rxdata)-1, 0);
	if(bytes < 0)
	{
		printk("recv failed\n");
		sockclose(sockfd);
		return;
	}

	/* make sure the data has a NULL on the end, so we can print it */
	*(rxdata+bytes)=0;
	printk("Got %d bytes:\n%s\n", bytes, rxdata);

	/* Close the socket - we're done */
	sockclose(sockfd);
}

