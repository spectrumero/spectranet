// Spectank spectator viewer for Unix.
// Deal with SDL graphics.

#include <SDL/SDL.h>
#include <SDL/SDL_gfxPrimitives.h>
#include <SDL/SDL_ttf.h>
#include <stdio.h>
#include <math.h>

#include "gfx.h"
#include "ctfmessage.h"

#define BOXSZ 16

SDL_Surface *surface;
SDL_Surface *background;
GfxSize gsize;

GfxLine *icon[MAXICONS];
int *clr[MAXMAPCLRS];
int fotonAnim;
int xplodeAnim;

int fotonClr;
int xplodClr;

TTF_Font *font;

DrawListElement *drawItems;
DrawListElement *eptr;

void initGfx(int width, int height) {
    int scaledWidth;
    int scaledHeight;
    SDL_PixelFormat *fmt;

    drawItems=NULL;
    fotonAnim=0;
    xplodeAnim=0;
    fotonClr=ZX_RED;
    xplodClr=ZX_YELLOW;

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
    clr[ZX_BLACK]=makeColour(0,0,0);
    clr[ZX_BLUE]=makeColour(0,0,255);
    clr[ZX_RED]=makeColour(255,0,0);
    clr[ZX_MAGENTA]=makeColour(255,255,0);
    clr[ZX_GREEN]=makeColour(0,255,0);
    clr[ZX_CYAN]=makeColour(0,255,255);
    clr[ZX_YELLOW]=makeColour(255,255,0);
    clr[ZX_WHITE]=makeColour(255,255,255);
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

    // Foton torpedo frames
    l=makeGfxLine(10,16,22,16);
    icon[FOTON1]=l;
    l->next=makeGfxLine(16,10,16,22);
    l=l->next;
    l->next=makeGfxLine(10,14,10,18);
    l=l->next;
    l->next=makeGfxLine(22,14,22,18);
    l=l->next;
    l->next=makeGfxLine(14,10,18,10);
    l=l->next;
    l->next=makeGfxLine(14,22,18,22);

    l=makeGfxLine(8,8,24,24);
    icon[FOTON2]=l;
    l->next=makeGfxLine(8,24,24,8);
    l=l->next;
    l->next=makeGfxLine(22,6,26,10);
    l=l->next;
    l->next=makeGfxLine(26,22,22,26);
    l=l->next;
    l->next=makeGfxLine(10,26,16,22);
    l=l->next;
    l->next=makeGfxLine(6,10,10,6);

    l=makeGfxLine(10,0,22,31);
    icon[FOTON3]=l;
    l->next=makeGfxLine(0,22,31,6);
    l=l->next;
    l->next=makeGfxLine(2,20,6,24);
    l=l->next;
    l->next=makeGfxLine(20,30,24,26);
    l=l->next;
    l->next=makeGfxLine(30,12,26,4);
    l=l->next;
    l->next=makeGfxLine(8,4,12,0);

    l=makeGfxLine(8,14,24,18);
    icon[FOTON4]=l;
    l->next=makeGfxLine(18,8,14,24);

    // Explosion frames
    l=makeGfxLine(8,6,12,10);
    icon[XPLODE1]=l;
    l->next=makeGfxLine(12,10,14,7);
    l=l->next;
    l->next=makeGfxLine(14,7,16,9);
    l=l->next;
    l->next=makeGfxLine(16,9,22,2);
    l=l->next;
    l->next=makeGfxLine(22,2,20,10);
    l=l->next;
    l->next=makeGfxLine(20,10,26,12);
    l=l->next;
    l->next=makeGfxLine(26,12,20,14);
    l=l->next;
    l->next=makeGfxLine(20,14,28,22);
    l=l->next;
    l->next=makeGfxLine(28,22,24,20);
    l=l->next;
    l->next=makeGfxLine(24,20,24,31);
    l=l->next;
    l->next=makeGfxLine(24,31,16,26);
    l=l->next;
    l->next=makeGfxLine(16,26,16,30);
    l=l->next;
    l->next=makeGfxLine(16,30,8,24);
    l=l->next;
    l->next=makeGfxLine(8,24,1,27);
    l=l->next;
    l->next=makeGfxLine(1,27,10,20);
    l=l->next;
    l->next=makeGfxLine(10,20,4,16);
    l=l->next;
    l->next=makeGfxLine(4,16,9,14);
    l=l->next;
    l->next=makeGfxLine(9,14,8,6);

    l=makeGfxLine(5,7,11,12);
    icon[XPLODE2]=l;
    l->next=makeGfxLine(11,12,16,5);
    l=l->next;
    l->next=makeGfxLine(16,5,18,12);
    l=l->next;
    l->next=makeGfxLine(18,12,25,8);
    l=l->next;
    l->next=makeGfxLine(25,8,21,15);
    l=l->next;
    l->next=makeGfxLine(21,15,30,22);
    l=l->next;
    l->next=makeGfxLine(30,22,19,22);
    l=l->next;
    l->next=makeGfxLine(19,22,18,30);
    l=l->next;
    l->next=makeGfxLine(18,30,9,21);
    l=l->next;
    l->next=makeGfxLine(9,21,8,31);
    l=l->next;
    l->next=makeGfxLine(8,31,6,20);
    l=l->next;
    l->next=makeGfxLine(6,20,1,14);
    l=l->next;
    l->next=makeGfxLine(1,14,7,16);
    l=l->next;
    l->next=makeGfxLine(7,16,5,7);

    l=makeGfxLine(2,0,8,0);
    icon[FLAGICON]=l;
    l->next=makeGfxLine(8,0,8,2);
    l=l->next;
    l->next=makeGfxLine(8,2,2,2);
    l=l->next;
    l->next=makeGfxLine(2,2,2,0);
    l=l->next;
    l->next=makeGfxLine(4,2,4,29);
    l=l->next;
    l->next=makeGfxLine(6,2,6,29);
    l=l->next;
    l->next=makeGfxLine(2,31,8,31);
    l=l->next;
    l->next=makeGfxLine(8,31,8,29);
    l=l->next;
    l->next=makeGfxLine(8,29,2,29);
    l=l->next;
    l->next=makeGfxLine(2,29,2,31);

    l=l->next;
    l->next=makeGfxLine(6,2,28,12);
    l=l->next;
    l->next=makeGfxLine(28,12,6,20);
    l=l->next;
    l->next=makeGfxLine(6,8,16,11);
    l=l->next;
    l->next=makeGfxLine(16,11,6,15);

    l=makeGfxLine(20,0,24,0);
    icon[FUELICON]=l;
    l->next=makeGfxLine(24,0,24,4);
    l=l->next;
    l->next=makeGfxLine(24,4,29,4);
    l=l->next;
    l->next=makeGfxLine(29,4,29,31);
    l=l->next;
    l->next=makeGfxLine(29,31,6,31);
    l=l->next;
    l->next=makeGfxLine(6,31,6,10);
    l=l->next;
    l->next=makeGfxLine(6,10,16,4);
    l=l->next;
    l->next=makeGfxLine(16,4,20,4);
    l=l->next;
    l->next=makeGfxLine(20,4,20,0);
    l=l->next;
    l->next=makeGfxLine(10,12,25,12);
    l=l->next;
    l->next=makeGfxLine(25,12,25,25);
    l=l->next;
    l->next=makeGfxLine(25,25,10,25);
    l=l->next;
    l->next=makeGfxLine(10,25,10,12);

    l=makeGfxLine(1,7,30,7);
    icon[AMMOICON]=l;
    l->next=makeGfxLine(30,7,30,30);
    l=l->next;
    l->next=makeGfxLine(30,30,3,30);
    l=l->next;
    l->next=makeGfxLine(3,30,3,15);
    l=l->next;
    l->next=makeGfxLine(1,15,5,15);
    l=l->next;
    l->next=makeGfxLine(5,15,5,7);
    l=l->next;
    l->next=makeGfxLine(1,15,1,7);
    l=l->next;
    l->next=makeGfxLine(5,12,30,9);
    l=l->next;
    l->next=makeGfxLine(1,15,1,24);


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

void manageSprite(SpriteMsg16 *msg) {
    int *cptr;
    switch(msg->id) {
        case PLAYER:
            showTank(msg);
            break;
        case FOTON:
            if(fotonClr > ZX_WHITE)
                fotonClr=ZX_RED;
            cptr=clr[fotonClr];
            if(fotonAnim > 3) 
                fotonAnim=0;
            drawLineGfx(msg->x >> 3, msg->y >> 3,
                    icon[FOTON1 + fotonAnim], surface,
                    cptr[0], cptr[1], cptr[2] ,255);
            fotonAnim++;
            fotonClr++;
            break;
        case XPLODE:
            xplodClr=(xplodClr == ZX_YELLOW) ? ZX_WHITE : ZX_YELLOW;
            cptr=clr[xplodClr];
            drawLineGfx(msg->x >> 3, msg->y >> 3,
                    icon[XPLODE1 + xplodeAnim], surface,
                    cptr[0], cptr[1], cptr[2] ,255);
            xplodeAnim = !xplodeAnim;
            break;
        case FLAG:
            cptr=clr[msg->colour & 0x07];
            drawLineGfx(msg->x >> 3, msg->y >> 3,
                    icon[FLAGICON], surface,
                    cptr[0],cptr[1],cptr[2],255);
            break;
        case FUEL:
            cptr=clr[ZX_GREEN];
            drawLineGfx(msg->x >> 3, msg->y >> 3,
                    icon[FUELICON], surface,
                    cptr[0], cptr[1], cptr[2], 255);
            break;
        case AMMO:
            cptr=clr[ZX_GREEN];
            drawLineGfx(msg->x >> 3, msg->y >> 3,
                    icon[AMMOICON], surface,
                    cptr[0], cptr[1], cptr[2], 255);
            break;
        default:
            fprintf(stderr, "unknown sprite id: %d\n", msg->id);
            break;
    }
}

// tanks are the only graphics that get rotated.
void showTank(SpriteMsg16 *msg) {
    int *tankClr=clr[msg->colour & 0x07];
    double rotation=msg->rotation ? (16 - msg->rotation) * 0.392699082f : 0;
    GfxLine *tank=rotateGfxLines(icon[TANK], rotation, 15, 15);

    drawLineGfx(msg->x >> 3, msg->y >> 3, tank, surface, 
            tankClr[0], tankClr[1], tankClr[2], 255);
    freeGfxLines(tank);
}

