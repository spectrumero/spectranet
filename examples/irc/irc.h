#ifndef __IRC__H
#define __IRC__H
/* irc.h
 * Definitions and function prototypes.
 *
 * Copyright (c) 2008 Dylan Smith
 *
 * The MIT License
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
 */

#define	NETBUFSZ	1024
#define NICKSZ		24
#define CHANSZ		32
#define PASSSZ		32
#define SVRSIZE		48
#define INPUTSZ		256
#define KBUFSZ		32

#define NICKTYPE_THEIRS	1	/* blue - stuff others wrote */
#define NICKTYPE_OURS 2		/* red - stuff we wrote */
#define NICKTYPE_PM 3		/* magenta - PM */

/* Structures */
/* Points to the full irc message which has been tokenized */
struct ircmsg 
{
	char *prefix;
	char *command;
	char *param;
	char *msg;
};

struct irccmd
{
	char *command;
	char *param;
};

/* Input routines */
extern void resetinput();
extern void handleKey(uchar key);
extern char *checkKey();
extern void clearInputArea();
extern void inputexit();
extern void inputinit();

/* Status line routines */
extern void setStatusLine(char *nick, char *chan);

/* 'Main window' output routines */
extern void mainprint(char *str);
extern void nickprint(char *nick, int mine);
extern void mainclear();
void quickscroll();
void removeUnprintables(char *str);

/* Server response parsing routines */
extern void parseIrcMessage(char *msg);
void parseNumResponse(struct ircmsg *im);
void parseOtherResponse(struct ircmsg *im);
void parseServerCmd(struct irccmd *ic);
void parseCtcp(struct ircmsg *im);
void chomp(char *str);

/* Send a message to the server */
extern void sendIrcMsg(char *msg, int bufsz);

/* Parse things that the user typed */
extern int parseUserCmd(char *cmd);
int parseSlashCmd(char *cmd);

/* OpenBSD string functions */
/*
extern size_t strlcat(char *dst, char *src, size_t siz);
extern size_t strlcpy(char *dst, char *src, size_t siz); */

/* Globals */
#ifndef __MAIN__C
extern char nick[NICKSZ];
extern char server[SVRSIZE];
extern char chan[CHANSZ];
extern char pass[PASSSZ];
#endif
#ifndef __INPUTLINE__C
extern char kbuf[KBUFSZ];
extern int bufoffset;
extern uchar allow_blank_string;
#endif

#endif
