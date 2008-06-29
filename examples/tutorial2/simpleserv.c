/* A simple TCP server - this goes along with the following:
 *  http://spectrum.alioth.net/doc/index.php/Spectranet:_Tutorial_2 */

#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>

main()
{
	int sockfd, connfd, bytes;
	struct sockaddr_in my_addr;
	char *txdata="Hello world\r\n";
	char rxdata[512];

	/* 0x0C clears the screen in the z88dk default console driver */
	putchar(0x0C);

	/* Create the socket */
	/* The first argument, AF_INET is the family. The Spectranet only
	   supports AF_INET at present. SOCK_STREAM in this context is
           for a TCP connection. */
	sockfd=socket(AF_INET, SOCK_STREAM, 0);
	if(sockfd < 0)
	{
		printk("Could not open the socket - rc=%d\n", sockfd);
		return;
	}

	/* Now set up the sockaddr_in structure. */
	/* Zero it out so that any fields we don't set are set to
	   NULL (the structure also contains the local address to bind to). 
	   We will listne to port 2000. */
	memset(&my_addr, 0, sizeof(my_addr));	/* zero out all fields */
	my_addr.sin_family=AF_INET;
	my_addr.sin_port=htons(2000);		/* Port 2000 */

	if(bind(sockfd, &my_addr, sizeof(my_addr)) < 0)
	{
		printk("Bind failed.\n");
		sockclose(sockfd);
		return;
	}

	/* The socket should now listen. The Spectranet hardware in
	   its present form doesn't support changing the backlog, but
           the second argument to listen should still be a sensible value */
	if(listen(sockfd, 1) < 0)
	{
		printk("listen failed.\n");
		sockclose(sockfd);
		return;
	}

	printk("Listening on port 2000.\n");

	/* Now wait for a connection. Do it in a loop, so that we wait
	   for a new connection after each one has closed.
	   The accept() function blocks until a connection is made. */
	while((connfd=accept(sockfd, NULL, NULL)) > 0)
	{
		printk("Connection established.\n");
		bytes=send(connfd, txdata, strlen(txdata), 0);
		if(bytes < 0)
		{
			printk("Send failed.\n");
			sockclose(connfd);
			break;
		}

		/* Now clear out the receive buffer. */
		memset(rxdata, 0, sizeof(rxdata));

		/* Receive the message the user types. If the first
		   character is 'x' we'll exit */
		bytes=recv(connfd, rxdata, sizeof(rxdata), 0);
		if(bytes < 0)
		{
			printk("Recv failed.\n");
			sockclose(connfd);
			break;
		}
		else
		{
			printk("Received %d bytes.\nMessage is: %s\n",
				bytes, rxdata);
		}
		
		/* Close the connection to the remote host. This
 		   leaves the original socket still listening */
		sockclose(connfd);
		if(*rxdata == 'x')
		{
			/* We received an 'x', exit. */
			break;
		}
	}

	/* Close the listening socket and exit. */
	sockclose(sockfd);
	printk("Finished.\n");
}

