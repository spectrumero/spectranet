#ifndef _MAP_H
#define _MAP_H

#define MAXCOLS 1024
typedef struct _maprow {
    void *next;
    char *mapdata;
} Maprow;

void loadMap(const char *filename);
void drawMap();
void drawMapRow(int row, char *rowdata);
void testRot(int x, int y, double radians);

#endif

