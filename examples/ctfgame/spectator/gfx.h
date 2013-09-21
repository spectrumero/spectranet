#ifndef _GFX_H
#define _GFX_H

#include <SDL/SDL.h>
#include "ctfmessage.h"

#ifndef bool
#define bool uchar
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

// Defines and function prototypes for SDL graphics.
// Map icons.
#define SPAWNPT     0
#define FLAGPT      1
#define AMMOPT      2
#define FUELPT      3
#define TANK        4
#define FOTON1      5
#define FOTON2      6
#define FOTON3      7
#define FOTON4      8
#define XPLODE1     9
#define XPLODE2     10
#define FLAGICON    11
#define FUELICON    12
#define AMMOICON    13
#define MAXICONS    14

#define ZX_BLACK    0
#define ZX_BLUE     1
#define ZX_RED      2
#define ZX_MAGENTA  3
#define ZX_GREEN    4
#define ZX_CYAN     5
#define ZX_YELLOW   6
#define ZX_WHITE    7

#define CLR_TEAM1   2
#define CLR_TEAM2   5
#define CLR_NEUTRAL 6

#define MAXMAPCLRS  8

#define BRIGHT      0x40
#define FLASH       0x80

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

typedef struct _drawlistel {
    GfxLine *lines;
    bool freeLines;
    int *colour;
    int x;
    int y;
    void *next;
} DrawListElement;

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

// Handle graphics messages
void manageSprite(SpriteMsg16 *msg);
void showTank(SpriteMsg16 *msg);

extern GfxSize gsize;

#endif
