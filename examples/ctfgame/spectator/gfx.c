// Spectank spectator viewer for Unix.
// Deal with SDL graphics.

#include <SDL/SDL.h>
#include <SDL/SDL_gfxPrimitives.h>
#include <SDL/SDL_ttf.h>
#include <stdio.h>
#include <math.h>

#include "gfx.h"

#define BOXSZ 16

SDL_Surface *surface;
SDL_Surface *background;
GfxSize gsize;

GfxLine *icon[MAXICONS];
int *clr[MAXMAPCLRS];

TTF_Font *font;

void initGfx(int width, int height) {
    int scaledWidth;
    int scaledHeight;
    SDL_PixelFormat *fmt;

    scaledWidth=width * BOXSZ * gsize.factor;
    scaledHeight=height * BOXSZ * gsize.factor;

    if(SDL_Init(SDL_INIT_EVERYTHING) < 0) {
        fprintf(stderr, "SDL init failed\n");
        exit(-1);
    }

    if((surface=SDL_SetVideoMode(scaledWidth,scaledHeight,32,
                    SDL_HWSURFACE|SDL_DOUBLEBUF)) == NULL) {
        fprintf(stderr, "Unable to create SDL surface\n");
        exit(-1);
    }
    fmt=surface->format;

    if((background=SDL_CreateRGBSurface
                (SDL_HWSURFACE, scaledWidth, scaledHeight, fmt->BitsPerPixel,
                  fmt->Rmask, fmt->Gmask, fmt->Bmask, fmt->Amask)) == NULL) {
        fprintf(stderr, "Unable to create background surface\n");
        exit(-1);
    }

    TTF_Init();
    if((font=TTF_OpenFont("/usr/share/fonts/truetype/freefont/FreeMono.ttf", 16)) == NULL) {
        fprintf(stderr, "Unable to open font\n");
        fprintf(stderr, "Error: %s\n", TTF_GetError());
        exit(-1);
    }

    SDL_Flip(surface);
}

void doneDrawing() {
    SDL_Flip(surface);
}

void shutdownGfx() {
    TTF_Quit();
    SDL_Quit();
}

void setGfxScale(double factor) {
    gsize.MapBoxX = BOXSZ * factor;
    gsize.MapBoxY = gsize.MapBoxX;
    gsize.factor = factor;
}

void drawMapBox(int x, int y) {
    int scaledX=(x * BOXSZ) * gsize.factor;
    int scaledY=(y * BOXSZ) * gsize.factor;

    rectangleRGBA(background, scaledX, scaledY,
            scaledX+gsize.MapBoxX, scaledY+gsize.MapBoxY,
            0,0,255,255);
}

void drawMapIcon(int x, int y, int iconid, int colourid) {
    int mapX, mapY;
    GfxLine *i=icon[iconid];
    int *c=clr[colourid];

    mapX=x * BOXSZ;
    mapY=y * BOXSZ; 
    
    drawLineGfx(mapX, mapY, i, background,
            c[0], c[1], c[2], 255);
}

void drawLineGfx(int x, int y, GfxLine *lg, SDL_Surface *sfc,
        int r, int g, int b, int a) {
    int sx, sy, ex, ey;

    do {
        sx=gsize.factor * (lg->startX + x);
        sy=gsize.factor * (lg->startY + y);
        ex=gsize.factor * (lg->endX + x);
        ey=gsize.factor * (lg->endY + y);

        lineRGBA(sfc, sx, sy, ex, ey, r, g, b, a);
    } while(lg=lg->next);
}

void blitBackground() {
    SDL_Rect destR;
    destR.x=0;
    destR.y=0;

    SDL_BlitSurface(background, NULL, surface, &destR);
}

void initColours() {
   clr[CLR_TEAM1]=makeColour(255,0,0);
   clr[CLR_TEAM2]=makeColour(0,255,255);
   clr[CLR_NEUTRAL]=makeColour(255,255,0);
}

int *makeColour(int r, int g, int b) {
    int *c=(int *)malloc(sizeof(int) * 3);
    c[0]=r;
    c[1]=g;
    c[2]=b;
    return c;
}

void initIcons() {
    // Spawn point
    GfxLine *l;
    l=makeGfxLine(0, 0, 6, 6);
    icon[SPAWNPT]=l;
    l->next=makeGfxLine(10, 10, 15, 15);
    l=l->next;
    l->next=makeGfxLine(0, 15, 6, 10);
    l=l->next;
    l->next=makeGfxLine(15, 0, 10, 6);

    // Flag point
    l=makeGfxLine(0, 0, 0, 15);
    icon[FLAGPT]=l;
    l->next=makeGfxLine(0,0,12,4);
    l=l->next;
    l->next=makeGfxLine(0,8,12,4);

    // Fuel point
    l=makeGfxLine(0,0,0,15);
    icon[FUELPT]=l;
    l->next=makeGfxLine(0,0,12,0);
    l=l->next;
    l->next=makeGfxLine(0,6,10,6);

    // Ammo point
    l=makeGfxLine(6, 0, 0, 15);
    icon[AMMOPT]=l;
    l->next=makeGfxLine(6, 0, 12, 15);
    l=l->next;
    l->next=makeGfxLine(3,9,9,9);

    // Tank
    l=makeGfxLine(10,0,21,0);
    icon[TANK]=l;
    l->next=makeGfxLine(21,0,25,5);
    l=l->next;
    l->next=makeGfxLine(25,5,25,30);
    l=l->next;
    l->next=makeGfxLine(25,7,29,7);
    l=l->next;
    l->next=makeGfxLine(29,7,29,27);
    l=l->next;
    l->next=makeGfxLine(29,27,25,27);
    l=l->next;
    l->next=makeGfxLine(25,30,6,30);
    l=l->next;
    l->next=makeGfxLine(21,31,10,31);
    l=l->next;
    l->next=makeGfxLine(6,30,6,5);
    l=l->next;
    l->next=makeGfxLine(6,5,10,0);
    l=l->next;
    l->next=makeGfxLine(2,27,6,27);
    l=l->next;
    l->next=makeGfxLine(2,27,2,7);
    l=l->next;
    l->next=makeGfxLine(2,7,6,7);
}

GfxLine *makeGfxLine(int sx, int sy, int ex, int ey) {
    GfxLine *g=(GfxLine *)malloc(sizeof(GfxLine));
    g->startX=sx;
    g->startY=sy;
    g->endX=ex;
    g->endY=ey;
    g->next=NULL;
    return g;
}

void freeGfxLines(GfxLine *l) {
    GfxLine *f;
    while(l->next) {
        f=l;
        l=l->next;
        free(f);
    }
    free(l);
}

// orgX and orgY are the origin offsets (what we will rotate around)
GfxLine *rotateGfxLines(GfxLine *l, double radians, int orgX, int orgY) {
    GfxLine *newl, *lptr;
    int sx, sy;
    int newsx, newsy;
    int ex, ey;
    int newex, newey;

    newl=NULL;

    // if I ever get round to making this run on a retro platform
    // this should be replaced by a fixed point matrix vector
    // multiplication.
    do {
        sx=l->startX-orgX;
        sy=l->startY-orgY;
        ex=l->endX-orgX;
        ey=l->endY-orgY;

        newsx=(sx * cos(radians))+(sy * sin(radians));
        newsy=(sx * -sin(radians))+(sy * cos(radians));
        
        newex=(ex * cos(radians))+(ey * sin(radians));
        newey=(ex * -sin(radians)) + (ey * cos(radians));

        if(newl == NULL) {
            lptr=makeGfxLine(newsx + orgX, newsy + orgY, 
                newex + orgX, newey + orgY);
            newl=lptr;
        }
        else {
            lptr->next=makeGfxLine(newsx + orgX, newsy + orgY, 
                newex + orgX, newey + orgY);
            lptr=lptr->next;
        }

    } while(l=l->next);

    return newl;
}

void testRot(int x, int y, double radians) {
    GfxLine *t=rotateGfxLines(icon[TANK], radians, 15, 15);
    drawLineGfx(x, y, t, surface, 255, 255, 255, 255);
    freeGfxLines(t);
}

void addText(const char *t) {
    SDL_Rect rect;
    SDL_Surface *text;
    SDL_Color color={255,255,255};
    if(!(text=TTF_RenderText_Blended(font, t, color))) {
        fprintf(stderr, "Can't render text\n");
        exit(-1);
    }

    rect.x=0;
    rect.y=surface->h-20;
    rect.w=text->w;
    rect.h=text->h;
    SDL_BlitSurface(text, NULL, surface, &rect);
    SDL_FreeSurface(text);
}

