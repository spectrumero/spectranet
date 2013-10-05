// Map loader for Spectank spectator client.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "gfx.h"
#include "map.h"

Maprow *map;

void loadMap(const char *filename) {
    FILE *stream;
    char txtrow[MAXCOLS+1];
    Maprow *curRow;
    int row=0;

    memset(txtrow, 0, sizeof(txtrow));
    map=(Maprow *)malloc(sizeof(Maprow));
    map->next=NULL;
    curRow=map;

    if((stream=fopen(filename, "r"))) {
        while(fgets(txtrow, MAXCOLS, stream)) {
            if(txtrow[0] != '*') {
                if(row > 0) {
                    curRow->next=(Maprow *)malloc(sizeof(Maprow));
                    curRow=curRow->next;
                    curRow->next=NULL;
                }
                curRow->mapdata=strdup(txtrow);
                row++;
            }
        }
    }
    else {
        perror("loading map");
        exit(-1);
    }

    initGfx(strlen(map->mapdata), row);
    drawMap();
}

void drawMap() {
    int row=0;
    Maprow *cur=map;

    while(cur->next) {
        drawMapRow(row, cur->mapdata);
        row++;
        cur=cur->next;
    }
}

void drawMapRow(int row, char *rowdata) {
    int i;
    int c;

    for(i=0; i < MAXCOLS; i++) {
        switch(*rowdata) {
            case 'B':
                drawMapBox(i, row);
                break;
            case 'a':
                drawMapIcon(i, row, FLAGPT, CLR_TEAM2);
                break;
            case 'b':
                drawMapIcon(i, row, FLAGPT, CLR_TEAM1);
                break;
            case 'f':
                drawMapIcon(i, row, FUELPT, CLR_NEUTRAL);
                break;
            case 'g':
                drawMapIcon(i, row, AMMOPT, CLR_NEUTRAL);
                break;
            case 0:
                return;
            default:
                if(*rowdata >= '0' && *rowdata <= '9') {
                    c=(*rowdata < '2') ? CLR_TEAM2 : CLR_TEAM1;
                    drawMapIcon(i, row, SPAWNPT, c);
                }
        }
        rowdata++;
    }
}

