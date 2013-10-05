// Main program for Spectank spectator mode.

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "gfx.h"

int main(int argc, char **argv) {
    char *mapfile=NULL;
    char *address=NULL;
    double scale=1.0f;
    int ch;

    while((ch=getopt(argc, argv, "a:m:s:")) != -1) {
        switch(ch) {
            case 'm':
                mapfile=optarg;
                break;
            case 'a':
                address=optarg;
                break;
            case 's':
                scale=strtof(optarg, NULL);
                break;
            default:
                usage(argv[0]);
        }
    }

    if(!mapfile || !address) {
        usage(argv[0]);
    }

    printf("Running\n");
    setGfxScale(scale);
    initColours();
    initIcons();

    loadMap(mapfile);

    makeSocket(address);
    messageLoop();

    return 0;
}

void usage(const char *cmd) {
    fprintf(stderr, "Usage: %s -m mapfile -a address [opts]\n", cmd);
    fprintf(stderr, "Options: \n");
    fprintf(stderr, " -s         Display scale factor\n");
    fprintf(stderr, "\n");
    exit(1);
}

