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

    makeSocket("172.16.0.33");
    messageLoop();

    return 0;
}
