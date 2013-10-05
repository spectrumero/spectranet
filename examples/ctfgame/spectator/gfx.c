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
SDL_Surface *scsurface;
GfxSize gsize;

GfxLine *icon[MAXICONS];
int *clr[MAXMAPCLRS];
int fotonAnim;
int xplodeAnim;

int fotonClr;
int xplodClr;

TTF_Font *font;
TTF_Font *scoreFont;
TTF_Font *pnameFont;
int cntrX;

DrawListElement *drawItems;
DrawListElement *eptr;

PlayerIdMsg players[MAXCLIENTS];

ScreenMsg smsgs[MAXSCRNMSGS];
int currmsg;
SDL_Surface *msgsfcs[MAXSCRNMSGS];

SDL_Surface *blueScoreSurface;
SDL_Surface *redScoreSurface;
SDL_Surface *namesfc;
SDL_Surface *goalsfc;

ScoreSurface scores[MAXCLIENTS];

uchar flashclock;

RotMat rotation[16]={
    {1.000,0.000,-0.000,1.000},
    {0.924,0.383,-0.383,0.924},
    {0.707,0.707,-0.707,0.707},
    {0.383,0.924,-0.924,0.383},
    {-0.000,1.000,-1.000,-0.000},
    {-0.383,0.924,-0.924,-0.383},
    {-0.707,0.707,-0.707,-0.707},
    {-0.924,0.383,-0.383,-0.924},
    {-1.000,-0.000,0.000,-1.000},
    {-0.924,-0.383,0.383,-0.924},
    {-0.707,-0.707,0.707,-0.707},
    {-0.383,-0.924,0.924,-0.383},
    {0.000,-1.000,1.000,0.000},
    {0.383,-0.924,0.924,0.383},
    {0.707,-0.707,0.707,0.707},
    {0.924,-0.383,0.383,0.924}
};

void initGfx(int width, int height) {
    int scaledWidth;
    int scaledHeight;
    SDL_PixelFormat *fmt;

    drawItems=NULL;
    fotonAnim=0;
    xplodeAnim=0;
    fotonClr=ZX_RED;
    xplodClr=ZX_YELLOW;
    scsurface=NULL;

    memset(players, 0, sizeof(players));
    memset(smsgs, 0, sizeof(smsgs));
    memset(scores, 0, sizeof(scores));
    currmsg=0;
    blueScoreSurface=NULL;
    redScoreSurface=NULL;

    scaledWidth=width * BOXSZ * gsize.factor;
    scaledHeight=(height * BOXSZ * gsize.factor) + 90;

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
    cntrX=surface->w/2;

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

    if((scoreFont=TTF_OpenFont("/usr/share/fonts/truetype/freefont/FreeSansBold.ttf", 100)) == NULL) {
        fprintf(stderr, "Unable to open score font\n");
        fprintf(stderr, "Error: %s\n", TTF_GetError());
        exit(-1);
    }

    if((pnameFont=TTF_OpenFont("/usr/share/fonts/truetype/freefont/FreeMono.ttf", 32)) == NULL) {
        fprintf(stderr, "Unable to open font\n");
        fprintf(stderr, "Error: %s\n", TTF_GetError());
        exit(-1);
    }
    createScoreboardText();
    SDL_Flip(surface);
}

void doneDrawing() {
    flashclock++;
    blitScreenMsgs();
    blitScores();
    blitWinner();
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

void drawViewportGrid(int w, int h) {
    int i;
    for(i=0; i < background->w; i+=(w*gsize.factor)) 
    {    
        lineRGBA(background, i, 0, i, background->h-100,
                32,32,32,255);
    }
    for(i=0; i < background->h-100; i+=(h*gsize.factor)) 
    {
        lineRGBA(background, 0, i, background->w, i,
                32,32,32,255);
    }
}

// orgX and orgY are the origin offsets (what we will rotate around)
GfxLine *rotateGfxLines(GfxLine *l, int rotindex, int orgX, int orgY) {
    GfxLine *newl, *lptr;
    int sx, sy;
    int newsx, newsy;
    int ex, ey;
    int newex, newey;
    RotMat *rotmat;

    rotmat=&rotation[rotindex];

    newl=NULL;

    // if I ever get round to making this run on a retro platform
    // this should be replaced by a fixed point matrix vector
    // multiplication.
    do {
        sx=l->startX-orgX;
        sy=l->startY-orgY;
        ex=l->endX-orgX;
        ey=l->endY-orgY;

        newsx=(sx * rotmat->x1y1)+(sy * rotmat->x1y2);
        newsy=(sx * rotmat->x2y1)+(sy * rotmat->x2y2);

        newex=(ex * rotmat->x1y1)+(ey * rotmat->x1y2);
        newey=(ex * rotmat->x2y1) + (ey * rotmat->x2y2);

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

void addText(const char *t, int x, int y) {
    SDL_Rect rect;
    SDL_Surface *text;
    SDL_Color color={255,255,255};
    if(strlen(t)) {
        if(!(text=TTF_RenderText_Blended(font, t, color))) {
            fprintf(stderr, "Can't render text at %d,%d: %s\n", 
                    x, y, SDL_GetError());
            exit(-1);
        }

        rect.x=x * gsize.factor;
        rect.y=y * gsize.factor;
        rect.w=text->w;
        rect.h=text->h;
        SDL_BlitSurface(text, NULL, surface, &rect);
        SDL_FreeSurface(text);
    }
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
    int *tankClr;
    uchar *owner;
    char buf[10];
    
    if(msg->flags & HASFLAG && flashclock & 0x08) {
        tankClr=clr[ZX_WHITE];
    }
    else
    {
        tankClr=clr[msg->colour & 0x07];
    }
    GfxLine *tank=rotateGfxLines(icon[TANK], msg->rotation, 15, 15);

    drawLineGfx(msg->x >> 3, msg->y >> 3, tank, surface, 
            tankClr[0], tankClr[1], tankClr[2], 255);
    freeGfxLines(tank);

    owner=strlen(players[msg->ownerid].ownername)
        ? players[msg->ownerid].ownername
        : (uchar *)"Unknown!";

    addText(owner, (msg->x >> 3) + 34, 
            (msg->y >> 3) - 4);

    snprintf(buf, sizeof(buf), "%d", msg->ammo);
    addText(buf, (msg->x >> 3) + 34, (msg->y >> 3) + 12);

    if(msg->lives != 255) {
        snprintf(buf, sizeof(buf), "%d", msg->lives);
        addText(buf, (msg->x >> 3) + 34, (msg->y >> 3) + 30);
    }

    showHealthBar(msg->health, msg->x >> 3, (msg->y >> 3) + 36);
}

void showHealthBar(int health, int x, int y) {
    int barx, bary;
    int width, height;
    int *barclr;

    if(health > 100) health=100;
    else if(health < 0) health=0;

    barx=gsize.factor * x;
    bary=gsize.factor * y;
    width=((double)health/100.0f) * (32.0f * gsize.factor);
    height=(gsize.factor * 3) + 1;

    if(health > 90)
        barclr=clr[ZX_GREEN];
    else if(health > 30)
        barclr=clr[ZX_YELLOW];
    else
        barclr=clr[ZX_RED];

    boxRGBA(surface, barx, bary, barx+width, bary+height,
            barclr[0], barclr[1], barclr[2], 255);

}

void handlePlayerIdMsg(PlayerIdMsg *msg) {
    memcpy(&players[msg->ownerid], msg, sizeof(PlayerIdMsg));
}

void addScreenMsg(const char *msg) {
    SDL_Color color={255,255,255};
    ScreenMsg *mptr=&smsgs[currmsg];

    strncpy(mptr->msg, msg, MAXSCRNMSGSZ);
    mptr->ttl=TTL;

    if(mptr->rendered != NULL) {
        SDL_FreeSurface(mptr->rendered);
    }

    if(!(mptr->rendered=TTF_RenderText_Blended(font, msg, color))) {
        fprintf(stderr, "Can't render status area text\n");
        exit(-1);
    }

    currmsg++;
    if(currmsg == MAXSCRNMSGS)
        currmsg=0;
}

void blitScreenMsgs() {
    int i;
    int mindex=currmsg;
    int y=surface->h - (24 * MAXSCRNMSGS);
    ScreenMsg *mptr;
    SDL_Rect rect;

    for(i=0; i < MAXSCRNMSGS; i++) {
        mptr=&smsgs[mindex];

        if(mptr->rendered != NULL) {
            rect.x=10;
            rect.y=y;
            rect.w=mptr->rendered->w;
            rect.h=mptr->rendered->h;
            SDL_BlitSurface(mptr->rendered, NULL, surface, &rect);
            mptr->ttl--;

            if(mptr->ttl == 0) {
                SDL_FreeSurface(mptr->rendered);
                mptr->rendered=NULL;
            }
        }
        y+=24;
        mindex++;
        if(mindex == MAXSCRNMSGS)
            mindex=0;
    }
}

void showScores(SpectatorScoreMsg *msg) {
    int i;
    char scoreString[8];
    SDL_Color team1={0,255,255};
    SDL_Color team2={255,0,0};
    SDL_Color scoreCol={64,255,64};
    ScoreSurface *ssfc;

    if(blueScoreSurface) {
        SDL_FreeSurface(blueScoreSurface);
        SDL_FreeSurface(redScoreSurface);
    }

    snprintf(scoreString, sizeof(scoreString),
            "%d", msg->team1score);
    blueScoreSurface=TTF_RenderText_Blended(scoreFont, scoreString,
            team1);
    snprintf(scoreString, sizeof(scoreString),
            "%d", msg->team2score);
    redScoreSurface=TTF_RenderText_Blended(scoreFont, scoreString,
            team2);

    for(i=0; i<MAXCLIENTS; i++) {
        // player surface is also used as a flag to indicate whether
        // this element should be displayed.
        ssfc=&scores[i];
        if(ssfc->player) {
            SDL_FreeSurface(ssfc->player);
            SDL_FreeSurface(ssfc->goals);
            ssfc->player=NULL;
        }
        if(msg->playerTeam[i] < 2) {
           
            if(strlen(players[i].ownername)) {
                ssfc->player= 
                    TTF_RenderText_Blended(pnameFont, 
                        players[i].ownername, scoreCol);
            }
            else {
                ssfc->player=
                    TTF_RenderText_Blended(pnameFont,
                            "Unknown!", scoreCol);
            }

            snprintf(scoreString, sizeof(scoreString),
                    "%d", msg->playerGoals[i]);
            ssfc->goals=TTF_RenderText_Blended(pnameFont,
                    scoreString, scoreCol);

            ssfc->team=msg->playerTeam[i];
        }
    }
    
}

void blitScores() {
    int i;
    SDL_Rect rect;
    ScoreSurface *ssfc;
    int teamY[2];
    teamY[0]=surface->h-68;
    teamY[1]=teamY[0];
    int displaceName;
    int displaceGoals;

    if(blueScoreSurface) {
        rect.x=cntrX-100;
        rect.y=surface->h-100;
        rect.w=blueScoreSurface->w;
        rect.h=blueScoreSurface->h;
        SDL_BlitSurface(blueScoreSurface, NULL, surface, &rect);

        rect.x=cntrX;
        rect.w=redScoreSurface->w;
        rect.h=redScoreSurface->h;
        SDL_BlitSurface(redScoreSurface, NULL, surface, &rect);
    }

    rect.x=cntrX + 100;
    rect.y=surface->h-100;
    rect.w=namesfc->w;
    rect.h=namesfc->h;
    SDL_BlitSurface(namesfc, NULL, surface, &rect);
    rect.x=cntrX + 350;
    SDL_BlitSurface(goalsfc, NULL, surface, &rect);
    rect.x=cntrX-500;
    SDL_BlitSurface(namesfc, NULL, surface, &rect);
    rect.x=cntrX-250;
    SDL_BlitSurface(goalsfc, NULL, surface, &rect);

    for(i=0; i < MAXCLIENTS; i++) {
        ssfc=&scores[i];
        if(ssfc->player) {
            displaceName=(ssfc->team) ? 100 : -500;
            displaceGoals=(ssfc->team) ? 350 : -250;

            rect.x=cntrX + displaceName;
            rect.y=teamY[ssfc->team];
            rect.w=ssfc->player->w;
            rect.h=ssfc->player->h;
            SDL_BlitSurface(ssfc->player, NULL, surface, &rect);
            
            rect.x=cntrX + displaceGoals;
            rect.w=ssfc->goals->w;
            rect.h=ssfc->goals->h;
            SDL_BlitSurface(ssfc->goals, NULL, surface, &rect);

            teamY[ssfc->team]+=32;
        }
    }
}

void showWinner(SpectatorGameEnd *msg) {
    char buf[64];
    SDL_Color msgclr={255,255,128};

    if(msg->teamWin == 0) {
        snprintf(buf, sizeof(buf), "Blue team wins %d : %d",
                msg->bluecapture, msg->redcapture);
    }
    else if(msg->teamWin == 1) {
        snprintf(buf, sizeof(buf), "Red team wins %d : %d",
           msg->redcapture, msg->bluecapture);
    }
    else {
        snprintf(buf, sizeof(buf), "Score draw! %d : %d",
                msg->bluecapture, msg->redcapture);
    }
    
    scsurface=TTF_RenderText_Blended(scoreFont,
                    buf, msgclr);

}

void blitWinner() {
    SDL_Rect rect;
    if(scsurface != NULL) {
        rect.x=cntrX - (scsurface->w/2);
        rect.y=(surface->h/2) - (scsurface->h/2);
        rect.w=scsurface->w;
        rect.h=scsurface->h;
        SDL_BlitSurface(scsurface, NULL, surface, &rect);
    }
}

void startGame() {
    // remove scoreboard
    if(scsurface) {
        SDL_FreeSurface(scsurface);
        scsurface=NULL;
    }
}


void showCountdown() {

}

void createScoreboardText() {
    SDL_Color titleCol={255,255,128};
    namesfc=TTF_RenderText_Blended(pnameFont,
            "Player", titleCol);
    goalsfc=TTF_RenderText_Blended(pnameFont,
            "Goals", titleCol);
}

