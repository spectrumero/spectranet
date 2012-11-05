// The MIT License
// 
// Copyright (c) 2011 Dylan Smith
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

#include <stdio.h>
#include <stdlib.h>

#ifndef NOGETOPT
#include <unistd.h>
#endif

#include "ctfserv.h"

int main(int argc, char **argv) {
  char *mapfile=NULL;

	// defaults: winning score, 3 flags
	// wall damage maximum = 50 energy
	// minimum number of players = 2
	// default lives is infinite
  int winScore=3;
  int wallDmg=50;
  int minPlayers=2;
  int lives=-1;
  int ch;
	int timeLimit=-1;

#ifdef NOGETOPT
  if(argc != 2) {
          fprintf(stderr, "Usage: %s <mapfile>\n", argv[0]);
          exit(-1);
  }
  mapfile=argv[1];
#else
  while((ch=getopt(argc, argv, "t:m:fd:p:l:c:")) != -1) {
    switch(ch) {
      case 'm':   // Mapfile
        mapfile=optarg;
        break;
      case 'f':   // Freeplay mode
        winScore=0;
        break;
      case 'd':		// How much damage a wall can do
        wallDmg=strtol(optarg, NULL, 10);
        break;
      case 'p':		// Minimum players required to start
        minPlayers=strtol(optarg, NULL, 10);
        break;
      case 'l':		// Max lives (-1 = infinite)
        lives=strtol(optarg, NULL, 10);
        break;
			case 'c':		// Flags to capture to win
				winScore=strtol(optarg, NULL, 10);
				break;
			case 't':		// Time limit
				timeLimit=strtol(optarg, NULL, 10);
				break;
      default:
        usage(argv[0]);
    }
  }
  if(!mapfile)
    usage(argv[0]);
  
#endif

  initPowerupList();
  if(loadMap(mapfile) < 0) {
    fprintf(stderr, "Can't load map\n");
    exit(-1);
  }

  if(makeSocket() < 0) {
          fprintf(stderr, "Can't make socket\n");
          exit(-1);
  }

  // Start the scoreboard.
  setupScreen();

  setWinningScore(winScore);
  setMaxWallCollisionDmg(wallDmg);
  setMinPlayers(minPlayers);
	setMaxLives(lives);
	setTimeLimit(timeLimit);

  initObjList();
  createFlags();
  if(messageLoop() < 0) {
          shutdownScoreboard();
          fprintf(stderr, "Message loop exited\n");
          exit(-1);
  }
}

void usage(char *cmd) {
  fprintf(stderr, "Usage: %s -m <mapfile> [opts]\n",cmd);
  fprintf(stderr, "Options:\n");
  fprintf(stderr, " -f          Freeplay mode (no winning score)\n");
  fprintf(stderr, " -d <value>  Max damage that a wall deals in a collision\n");
  fprintf(stderr, " -p <value>  Minimum number of players to start a game\n");
  fprintf(stderr, " -l <value>  How many lives a player has\n");
	fprintf(stderr, " -c <value>  Capture this many flags to win\n");
	fprintf(stderr, " -t <value>  Time limit (in seconds)\n");
  fprintf(stderr, "\n");
  exit(1);
}

