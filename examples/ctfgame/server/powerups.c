// The MIT License
// 
// Copyright (c) 2011 Dylan Smith
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

// Handle power-up objects.
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "ctfmessage.h"
#include "ctfserv.h"

PowerSpawn	*powerups[MAXPWRSPAWNS];
int pwridx;

void initPowerupList() {
	srand(time(NULL));
	memset(powerups, 0, sizeof(powerups));
	pwridx=0;
}

void addPowerup(MapXY location, int tiletype) {
	PowerSpawn *s;
	if(pwridx == MAXPWRSPAWNS) {
		fprintf(stderr, "Too many powerup spawns; ignoring\n");
		return;
	}
	
	s=(PowerSpawn *)malloc(sizeof(PowerSpawn));
	s->x = location.mapx << 4;
	s->y = location.mapy << 4;
	s->cooldown = getCooldown();

	switch(tiletype) {
		case 'f':	// fuel
			s->type = FUELID;
			break;
		case 'g':	// ammo (guns)
			s->type = AMMOID;
			break;
		default:
			fprintf(stderr, "Unknown powerup spawn: %d\n", tiletype);
			exit(-1);
	}

	powerups[pwridx]=s;
	pwridx++;
}

// Get the cooldown time. This is done in such a way that it doesn't really
// matter what RAND_MAX is, it shoudl come up with something sensible
int getCooldown() {
	int r = rand() % MAXPWRCOOLDOWN;
	if(r < MINPWRCOOLDOWN)
		r=MINPWRCOOLDOWN;
	return r;
}

// Update spawn cooldowns and create objects.
// Executed once per frame.
void updatePowerSpawns() {
	int i;
	PowerSpawn *sptr;

	for(i = 0; i < pwridx; i++) {
		sptr = powerups[i];
		if(sptr->cooldown == 1) {
			spawnPowerup(sptr);
		}

		if(sptr->cooldown != 0) {
			sptr->cooldown--;
		}
	}
}

// Create powerups when the spawnpoint cooldown has been reached.
void spawnPowerup(PowerSpawn *sp) {
	Object *obj = newObject(sp->type, -1, sp->x, sp->y);
	obj->team = -1;
	obj->extras = sp;
	obj->destructFunc = resetPowerupSpawn;
	obj->collisionFunc = powerupTouched;
	obj->colour = WHITE;
	addObject(obj);
}

// Reset the spawn points.
void resetPowerupSpawnPoints() {
	int i;
	PowerSpawn *sptr;

	for(i=0; i < pwridx; i++) {
		sptr = powerups[i];
		sptr->cooldown = getCooldown();
	}
}

// Powerup destruction callback
void resetPowerupSpawn(Object *pwrup) {
	PowerSpawn *sptr=(PowerSpawn *)pwrup->extras;
	sptr->cooldown = getCooldown();
}

// Powerup collision callback
void powerupTouched(Object *powerup, Object *with) {

	// Only tanks get modified by touching a powerup.
	if(with->type == PLYRTANKID) {
		switch(powerup->type) {
			case FUELID:
				with->hp += FUELINC;
				if(with->hp > MAXHP)
					with->hp = MAXHP;
				break;
			case AMMOID:
				with->ammo += AMMOINC;
				if(with->ammo > MAXAMMO)
					with->ammo = MAXAMMO;
				addAmmoMsg(with);
		}
	}
}

