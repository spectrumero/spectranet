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

// Map loader and map functions.
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "ctfserv.h"
#include "ctfmessage.h"

Maptile *map;
Maptile *maprow[MAXROWS];
int lastrow;

MapXY spawnpoints[10];
MapXY flags[2];

// Load the map.
int loadMap(const char *filename) {
	FILE *stream;
	char txtrow[MAXCOLS+1];
	int row=0;
	memset(maprow, 0, sizeof(maprow));

	if((stream = fopen(filename, "r"))) {
		while(fgets(txtrow, MAXCOLS, stream)) {
			maprow[row]=buildMapRow(txtrow, row);
			row++;
		}
		fclose(stream);

	} else {
		perror("loadMap: open");
		fprintf(stderr,"Map file is: %s\n", filename);
		return -1;
	}
	lastrow=row-1;
	printf("Loaded map: Rows = %d\n", row);
	return 0;
}

// Interpret each map row line and store it in memory.
// Returns a pointer to first Maptile in the map's row.
Maptile *buildMapRow(char *txtrow, int y) {
	int i, spawn, team;
	MapXY mxy;
	Maptile *tile;
	Maptile *row=NULL;
	Maptile *prev=NULL;
	for(i=0; i<MAXCOLS; i++) {
		if(*txtrow >= '0' && *txtrow <= '9') {
			spawn = *txtrow-'0';
			spawnpoints[spawn].mapx = i << 3;
			spawnpoints[spawn].mapy = y << 3;

			// Change to spawn point tile
			*txtrow='s';
		}
		else if(*txtrow == 'a' || *txtrow == 'b') {
			team = *txtrow - 'a';
			flags[team].mapx = i << 3;
			flags[team].mapy = (y-2) << 3;
		}
		else if(*txtrow == 'f' || *txtrow == 'g') {
			mxy.mapx = i << 3;
			mxy.mapy = (y-2) << 3;
			addPowerup(mxy, *txtrow);
		}

		if(*txtrow > 32) {
			tile=(Maptile *)malloc(sizeof(Maptile));
			tile->x=i;
			tile->flags=0;			// TODO: set flags
			tile->tile=*txtrow;
			tile->next=NULL;
			if(!row)
				row=tile;
			if(prev)
				prev->next=tile;
			prev=tile;
		}

		// End of line?
		else if(*txtrow == '\r' || *txtrow == '\n' || *txtrow == 0) {
			break;
		}
		txtrow++;			
	}
	return row;
}

// Create a client message containing the tiles in the viewport.
int sendMapMsg(int clientid, Viewport *vp) {
	int x,y, miny, maxy, minx, maxx;
	Maptile *tile;
	uchar msg[MAXMAPMSG];
	uchar *msgptr=&msg[4];
	MaptileMsg mtm;
	uint16_t ntiles=0;
	msg[0]=1;
	msg[1]=MAPMSG;

	// Tile coordinates are pixel/8
	miny=vp->ty >> 3;
	maxy=vp->by >> 3;
	minx=vp->tx >> 3;
	maxx=vp->bx >> 3;
	if(maxy > lastrow)
		maxy=lastrow;

	for(y=miny; y < maxy; y++) {
		tile=maprow[y];

		while(tile->x < maxx) {
			if(msgptr - msg > MAXMAPMSG) {
				fprintf(stderr, "Map message is too big: client %d topx=%d topy=%d ntiles=%d\n",
						clientid, minx, miny, ntiles);

				// Send whatever it is we have managed to build.
				memcpy(&msg[2], &ntiles, sizeof(uint16_t));
				return sendMessageBuf(clientid, msg, msgptr-msg);
			}
			if(tile->x >= minx) {
				mtm.tile=tile->tile;
				mtm.x=tile->x - minx;
				mtm.y=y - miny;
				memcpy(msgptr, &mtm, sizeof(MaptileMsg));
				msgptr+=sizeof(MaptileMsg);
				ntiles++;
			}
			tile=tile->next;
			if(!tile)
				break;
		}
	}
	memcpy(&msg[2], &ntiles, sizeof(uint16_t));
	printf("Sent %d tiles\n", ntiles);
	return sendMessageBuf(clientid, msg, msgptr-msg);	
  return 0;
}

// Detect collisions with the map.
bool detectMapCollision(Object *obj) {
	Maptile *t;
	int objy=obj->y >> 7;
	unsigned long tx;
	unsigned long txmax;
	unsigned long obxmax;

	// Ignore the flag (hopefully enough of it will stick out of the
	// map that someone can still get it)
	if(obj->type == FLAGID)
		return FALSE;

	do {
		if(objy > lastrow)
			return FALSE;

		t=maprow[objy];
		while(t) {
			// Find object X pixel
			tx = t->x << 7;
			txmax = tx + 128;

			obxmax = obj->x + 256;

			// No need to consider any more tiles in the row list
			// when the maximum extent of the object is smaller than
			// the minimum extent of the tile
			if(obxmax < tx)
				break;

			// Only consider collidable tiles.
			if(t->tile >= 'A' && t->tile <= 'Z') {

				// check for horizontal overlap
				if(tx >= obj->x && tx <= obxmax)
					return TRUE;
				if(txmax >= obj->x && txmax <= obxmax)
					return TRUE;
			}
			t=t->next;
		} 

		objy++;
	} while(objy << 7 < obj->y+256);

	return FALSE;
}

// Determine if an object is touching a given team's flag point
bool detectTouchingFlagpoint(Object *obj) {
	int fpx, fpy;

	fpx=flags[obj->team].mapx << 4;
	fpy=flags[obj->team].mapy << 4;

	if(abs(obj->x - fpx) < 256 &&
			abs(obj->y - fpy) < 256)
		return TRUE;
	return FALSE;
}

// Get a spawn point. This just picks the struct from the
// array for now but it's in a function to allow us to easily 
// modify things later.
MapXY getSpawnpoint(int player) {
	return spawnpoints[player];
}

// Get a flag point. See comment above...
MapXY getFlagpoint(int team) {
	return flags[team];
}

