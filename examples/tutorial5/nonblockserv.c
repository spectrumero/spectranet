/* A demonstration of the use of poll to avoid blocking. This allows
 * multiple sockets to be read and accepted, and interleaved with keypresses.
 *
 * Compile with:
 * zcc +zx -vn -O2 -o nonblockserv.bin nonblockserv.c -lndos -llibsocket */

#include <stdio.h>
#include <input.h>		/* for in_Inkey() */
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sockpoll.h>

main()
{
	int sockfd, connfd, polled, rc;
	struct sockaddr_in my_addr;
	char txdata[40];
	char rxdata[128];
	struct pollfd p;	/* the poll information structure */

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

	/* Now wait for things to happen. Contrast this with the server
	   code example in tutorial 2. Note that instead of calling accept()
	   we start a loop, and use the pollall() function to poll all open
	   sockets. When pollall() finds some data ready, it returns
	   status telling us why the socket was ready, so we can act
	   appropriately */
	while(1)
	{
		/* This shows the keyboard being multiplexed with sockets */
		if(in_Inkey() == 'x')
			break;	/* user requested to exit */

		/* pollall() fills a pollfd struct when something happens.
		   It returns the socket descriptor on which that something
		   happened */
		polled=pollall(&p);

		/* Was the socket descriptor the listening socket? */
		if(polled == sockfd)
		{
			/* Yes. So accept the incoming connection. */
			printk("Accepting a new connection...\n");
			connfd=accept(sockfd, NULL, NULL);
		}
		/* if any other socket descriptor returned status, then
		   something happened on a communication socket */
		else if(polled > 0)
		{
			/* Did the other end hang up on us? */
			if(p.revents & POLLHUP)
			{
				printk("Remote host disconnected\n");

				/* ...so close our end too and free the fd */
				sockclose(polled);
			}
			/* No, the other end didn't hang up */
			else
			{
				/* Some data is ready to collect */
				rc=recv(polled, rxdata, sizeof(rxdata)-1, 0);
				if(rc < 0)
				{
					printk("recv failed!\n");
					sockclose(polled);
					continue;
				}
		
				/* Ensure there's a null on the end */
				*(rxdata+rc)=0;
			
				/* and print it */
				printk("Received: %s\n", rxdata);

				/* Send some data back to the client */
				sprintf(txdata, "You sent %d bytes\r\n", rc);
				rc=send(polled, txdata, strlen(txdata), 0);
				if(rc < 0)
				{
					printk("send failed!\n");
					sockclose(polled);
					continue;
				}
			}
		}
	}			

	/* Close the listening socket and exit. */
	sockclose(sockfd);
	printk("Finished.\n");
}

