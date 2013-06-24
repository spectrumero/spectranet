/* 
 * The MIT License
 *
 * Copyright (c) 2010 Dylan Smith
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
*/
#define UI_INK		55
#define UI_PAPER	48
#define USERSZ		20
#define PASSWDSZ	20
#define TWEETSZ		140

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include "tweet.h"

#ifdef NIXIE_DISPLAY
#include "spi-nixie.h"
void charsRemaining(int remain);
void tweetsSent();
#endif

char *user=NULL;
char *passwd=NULL;
char *tweet=NULL;

char *lastuser=NULL;
char *lasttweet=NULL;
int tweets=0;

#ifdef NIXIE_DISPLAY
void charsRemaining(int remain) {
	display_int(remain, 2);
}

void tweetsSent() {
	display_ra_int(tweets);
}
#endif

int ui_init()
{
	#ifdef NIXIE_DISPLAY
	spi_init();
	tweetsSent();
	#endif
	user=(char *)malloc(USERSZ);
	passwd=(char *)malloc(PASSWDSZ);
	tweet=(char *)malloc(TWEETSZ);

	lastuser=(char *)malloc(USERSZ);
	lasttweet=(char *)malloc(TWEETSZ);

	if(!user || !passwd || !tweet || !lastuser || !lasttweet)
		return 0;

	*user=0;
	*tweet=0;
	*lastuser=0;
	*lasttweet=0;
	return 1;
}

void mainMenu()
{
	uchar key;
	while(1)
	{
#ifdef NIXIE_DISPLAY
		tweetsSent();
#endif
		ia_cls();
		setpos(10,0);
		printk("\x10\x36Welcome to ZX Twitter. Press:\n");
		printk("\n\x10\x34[1]\x10\x37 Make a tweet\n\x10\x34[9]\x10\x37 Exit");

		if(*lastuser)
		{
			printk("\n\nLast tweet...\nFrom:\x10\x34 %s\n", lastuser);
			printk("\n\x10\x35%s", lasttweet);
		}
		
		key=getSingleKeypress();
		if(key == '9') return;
		if(key == '1') makeTweet();	
	}
}

int makeTweet()
{
	char *str;
	uchar key;
	int rc;

	ia_cls();
	setpos(10,0);
	printk("Leaving a field blank aborts\n\n");
	printk("\x10\x36Username:\nPassword:\n\nYour tweet:\n");

	str=abortablekbinput(11, 12, USERSZ+1, 1, USERSZ, 0, NULL);
	if(!str) return 0;
	memcpy(user, str, USERSZ);

	str=abortablekbinput(11, 13, PASSWDSZ+1, 1, PASSWDSZ, 1, NULL);
	if(!str) return 0;
	memcpy(passwd, str, PASSWDSZ);

#ifdef NIXIE_DISPLAY
	str=abortablekbinput(0, 16, 32, 5, TWEETSZ, 0, charsRemaining);
#else
	str=abortablekbinput(0, 16, 32, 5, TWEETSZ, 0, NULL);
#endif
	if(!str) return 0;
	memcpy(tweet, str, TWEETSZ);

	rc=dotweet(user, passwd, tweet);
	if(rc >= 0)
	{
		memcpy(lastuser, user, USERSZ);
		memcpy(lasttweet, tweet, TWEETSZ);
#ifdef NIXIE_DISPLAY
		tweets++;
#endif
	}
	printk("Press 'c' to continue.");
	while(getSingleKeypress() != 'c');
}

void ui_status(int code, char *msg)
{
	setpos(22,0);
	setUIAttrs();
	printk("                               ");
	setpos(22,0);
	printk("\x10\x36\x11\x32");
	if(!msg)
	{
		switch(code)
		{
			case 200:
			printk("HTTP/1.1 200: Tweet successful\n");
			break;

			case 401:
			printk("HTTP/1.1 401; Bad user/password\n");
			break;

			default:
			printk("HTTP/1.1 %d: Probably failed!\n", code);
		}
	}
	else
	{
		if(code == 0)
			printk("%s\n", msg);
		else
			printk("Code %d - %s\n", code, msg);
	}
	setUIAttrs();
}

char *abortablekbinput
	(int x, int y, int wid, int ht, int sz, char pw,
	 void *callback)
{
	char *str;
	char kb;

	while(1)
	{
		resetinput(x, y, wid, ht, sz, callback);
		str=kbinput(pw);
		if(!*str)
		{
			setpos(22,0);
			setUIAttrs();
			printk("\x10\x36Sure you want to abort?\x10\x34 (Y/N)");
			while(1)
			{
				kb=getSingleKeypress();
				if(kb) break;
			}

			setpos(22, 0);
			printk("                                ");
			if(kb == 'y')
				return NULL;
		}
		else
			break;
	}
	return str;
}

void ia_cls()
{
	int i;

	/* 32 cols */
	putchar(1);
	putchar(32);
	putchar(19);
	putchar(1);

	setUIAttrs();

	/* cursor position */
	putchar(22);
	putchar(40);
	putchar(32);

	for(i=0; i<511;i++)
	{
		putchar(32);
	}
}

void setUIAttrs()
{
	putchar(16);
	putchar(UI_INK);
	putchar(17);
	putchar(UI_PAPER);
}

void setpos(char y, char x)
{
	putchar(22);
	putchar(y+32);
	putchar((x*2)+32);
}

