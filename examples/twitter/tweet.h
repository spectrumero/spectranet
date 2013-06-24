#ifndef __TWEET__H
#define __TWEET__H
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

/* Global state */
extern char *user;
extern char *passwd;
extern char *tweet;

/* Function prototypes */
void tweet_loadscr();
extern void resetinput(char sx, char sy, char wid, char hgt, int len,
	void *callback);
extern void clearArea(char ink, char paper);
extern void moveToCurrent();
extern char *checkKey();
extern void inputinit();
extern void inputexit();
extern char *kbinput(char ispass);
/*extern char getSingleKeypress();*/
extern void colourArea(char ink, char paper);

extern int ui_init();
extern void ia_cls();
extern void setUIAttrs();
extern void mainMenu();
extern void setpos(char y, char x);
extern int makeTweet();
extern char *abortablekbinput(int x, int y, int wid, int ht, int sz, char pw,
	void *callback);
extern void ui_status(int code, char *msg);

extern int dotweet(char *user, char *passwd, char *tweet);

#endif

