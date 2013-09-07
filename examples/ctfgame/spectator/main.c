// Main program for Spectank spectator mode.

#include <stdio.h>
#include <unistd.h>
#include "gfx.h"

int main(int argc, char **argv) {
    int i;
    double radians=0;
    printf("Running\n");
    setGfxScale(1);
    initColours();
    initIcons();

    loadMap("map.txt");

    for(i=0; i < 500; i++) {

        blitBackground();
        testRot(i,100,radians);
        addText("This is a test");
        doneDrawing();
        usleep(10000);
        radians+=0.1;
    }

    blitBackground();
    testRot(100,100,0);
    doneDrawing();

    sleep(10);
    return 0;
}
