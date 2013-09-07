#ifndef _GFX_H
#define _GFX_H

#include <SDL/SDL.h>

// Defines and function prototypes for SDL graphics.
// Map icons.
#define SPAWNPT     0
#define FLAGPT      1
#define AMMOPT      2
#define FUELPT      3
#define TANK        4
#define MAXICONS    5

#define CLR_TEAM1   0
#define CLR_TEAM2   1
#define CLR_NEUTRAL 2
#define MAXMAPCLRS  3

typedef struct _gfxsize {
    int MapBoxX;
    int MapBoxY;
    double factor;
} GfxSize;

typedef struct _gfxline {
    int startX;
    int startY;
    int endX;
    int endY;
    void *next;
} GfxLine;

void initGfx(int width, int height);
void shutdownGfx();
void setGfxScale(double factor);
void drawMapBox(int x, int y);
void blitBackground();
void doneDrawing();
void drawMapIcon(int x, int y, int iconid, int colourid);
void drawLineGfx(int x, int y, GfxLine *lg, SDL_Surface *sfc,
        int r, int g, int b, int a);

void initColours();
void initIcons();
int *makeColour(int r, int g, int b);
GfxLine *makeGfxLine(int sx, int sy, int ex, int ey);
GfxLine *rotateGfxLines(GfxLine *l, double radians, int orgX, int orgY);
void freeGfxLines(GfxLine *l);

void testRot(int x, int y, double radians);

void addText(const char *text);

extern GfxSize gsize;

#endif
