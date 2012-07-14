// The MIT License
// 
// Copyright (c) 2012 Dylan Smith
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

// ncurses based scoreboard for when the server is run interactively.
// Use the -DUSECURSES option in CFLAGS to enable.

#ifdef USECURSES
#include <curses.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include "ctfserv.h"

#ifdef USECURSES
WINDOW *msgwin;
WINDOW *blueTeamWin;
WINDOW *redTeamWin;
WINDOW *blueFlagWin;
WINDOW *redFlagWin;
#endif
FILE *scstream;

/* TODO: some kind of option */
#define SCOREFILE "spectankscore"

bool addname[2];

void setupScreen() {
#ifdef USECURSES
	int row, col, i;
	initscr();
	start_color();

	cbreak();
	nodelay(stdscr, TRUE);
	init_pair(1, COLOR_CYAN, COLOR_BLUE);
	init_pair(2, COLOR_WHITE, COLOR_RED);
	init_pair(3, COLOR_CYAN, COLOR_BLACK);
	init_pair(4, COLOR_YELLOW, COLOR_BLACK);

	getmaxyx(stdscr, row, col);

	mvprintw(0, 0, "Blue Team Score");
	mvprintw(0, (col/2)+4, "Red Team Score");
	refresh();

	blueTeamWin=mkwin(row/2, col/2-4, 1, 0);
	redTeamWin=mkwin(row/2, col/2-4, 1, (col/2)+4);
	blueFlagWin=mkwin(row/2, 3, 1, col/2-3);
	redFlagWin=mkwin(row/2, 3, 1, col/2);
	msgwin=mkwin((row/2)-1, col, (row/2)+2, 0);

	wbkgd(blueTeamWin, COLOR_PAIR(1));
	wbkgd(blueFlagWin, COLOR_PAIR(1));
	wbkgd(redTeamWin, COLOR_PAIR(2));
	wbkgd(redFlagWin, COLOR_PAIR(2));
	wbkgd(msgwin, COLOR_PAIR(3));

	wrefresh(blueTeamWin);
	wrefresh(redTeamWin);
	wrefresh(blueFlagWin);
	wrefresh(redFlagWin);
	wrefresh(msgwin);
#endif
	loadScores();
}

void shutdownScoreboard() {
#ifdef USECURSES
	endwin();
#endif
}

#ifdef USECURSES
WINDOW *mkwin(int height, int width, int starty, int startx) {
	WINDOW *w;

	w=newwin(height, width, starty, startx);
	scrollok(w, TRUE);
	wrefresh(w);
	return w;
}
#endif

void printMessage(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);

#ifdef USECURSES
	wattron(msgwin, COLOR_PAIR(3));
	vwprintw(msgwin, fmt, argp);
	wprintw(msgwin, "\n");
	wrefresh(msgwin);
#else
	vprintf(fmt, argp);
	printf("\n");
#endif

	va_end(argp);
}

void printError(const char *fmt, ...) {
	va_list argp;
	va_start(argp, fmt);

#ifdef USECURSES
	wattron(msgwin, A_BOLD|COLOR_PAIR(4));
	vwprintw(msgwin, fmt, argp);
	wprintw(msgwin, "\n");
	wrefresh(msgwin);
	wattroff(msgwin, A_BOLD);
#else
	vfprintf(stderr, fmt, argp);
#endif

	va_end(argp);
}


void newScore(bool write) {
#ifdef USECURSES
	wprintw(blueTeamWin, "\n");
	wprintw(redTeamWin, "\n");
	wprintw(blueFlagWin, "\n");
	wprintw(redFlagWin, "\n");
	addname[0]=FALSE;
	addname[1]=FALSE;
#endif
	if(write) {
		scstream=fopen(SCOREFILE, "a");
		if(!scstream) 
			printError("Unable to write to scorefile: errno=%d", errno);
		fprintf(scstream,"-\n");
	}
	else {
		scstream=NULL;
	}
}

void addPlayerName(int team, char *name, int winner) {
#ifdef USECURSES
	WINDOW *tw;
	if(team > 1) return;

	tw = team ? redTeamWin : blueTeamWin;

	if(team == winner)
		wattron(tw, A_BOLD);
	else
		wattroff(tw, A_BOLD);

	if(addname[team])
		wprintw(tw, "/%s", name);
	else {
		addname[team]=TRUE;
		wprintw(tw, "%s", name);
	}
	wrefresh(tw);
#endif
	if(scstream)
		fprintf(scstream, "p %d %s %d\n", team, name, winner);
}

void addTeamScore(int team, int score, int winner) {
#ifdef USECURSES
	WINDOW *tw;
	if(team > 1) return;

	tw = team ? redFlagWin : blueFlagWin;
	if(team == winner)
		wattron(tw, A_BOLD);
	else
		wattroff(tw, A_BOLD);

	wprintw(tw, "%d", score);
	wrefresh(tw);
#endif
	if(scstream)
		fprintf(scstream, "t %d %d %d\n", team, score, winner);
}

void endScore() {
	if(scstream) {
		fclose(scstream);
		scstream=NULL;
	}
}

void loadScores() {
	FILE *sb;
	char buf[80];
	int team, score, winner;
	char name[80];

	if((sb=fopen(SCOREFILE, "r")) != NULL) {
		while(fgets(buf, sizeof(buf), sb)) {
			switch(*buf) {
				case '-':
					newScore(FALSE);
					break;
				case 't':
					sscanf(buf, "t %d %d %d\n", &team, &score, &winner);
					addTeamScore(team, score, winner);
					break;
				case 'p':
					sscanf(buf, "p %d %s %d\n", &team, name, &winner);
					addPlayerName(team, name, winner);
					break;
				default:
					printError("Unknown item in score file: %s", buf);
			}
		}
		fclose(sb);
	}
	else 
		printError("Unable to load scorefile: errno = %d", errno);
}
