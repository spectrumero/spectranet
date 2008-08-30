/* Test the libspectranet library. */

#include <stdio.h>
#include <spectranet.h>

void main()
{
	in_addr_t ip, netmask, gw;
	char ipbuf[19]; /* big enough for mac addr */
	char mac[6];

	/* cls */
	putchar(0x0c);

	printk("libspectranet test program\nIP settings:\n");
	
	get_ifconfig_inet(&ip);
	get_ifconfig_netmask(&netmask);
	get_ifconfig_gw(&gw);
	
	long2ipstring(&ip, ipbuf);
	printk("IP address:     %s\n", ipbuf);
	long2ipstring(&netmask, ipbuf);
	printk("Netmask   :     %s\n", ipbuf);
	long2ipstring(&gw, ipbuf);
	printk("Gateway   :     %s\n\n", ipbuf);

	printk("Hardware settings:\n");
	
	gethwaddr(mac);
	mac2string(mac, ipbuf);
	printk("MAC addr  :     %s\n", ipbuf);
}

