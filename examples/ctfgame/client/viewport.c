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

// Deal with viewports.
#include "ctf.h"
#include "ctfmessage.h"

// The player's viewport
Viewport vp;

// Sets the viewport from the supplied map XY coords.
void findViewport(MapXY *xy) {
	vp.tx=xy->mapx / VPXPIXELS;
	vp.ty=xy->mapy / VPYPIXELS;
	vp.bx=vp.tx+VPXPIXELS;
	vp.by=vp.ty+VPYPIXELS;
	sendViewportMsg(&vp);
}

// Moves the viewport right
int viewportRight() {
	if(vp.tx+VPXPIXELS > MAXVPX)
		return VPRANGE;
	vp.tx += VPXPIXELS;
	vp.bx += VPXPIXELS;
	return sendViewportMsg(&vp);
}

// Moves the viewport left
int viewportLeft() {
	if(vp.tx < VPXPIXELS)
		return VPRANGE;
	vp.tx -= VPXPIXELS;
	vp.bx -= VPYPIXELS;
	return sendViewportMsg(&vp);
}

// Moves the viewport down
int viewportDown() {
	if(vp.ty+VPYPIXELS > MAXVPY)
		return VPRANGE;
	vp.ty += VPYPIXELS;
	vp.by += VPYPIXELS;
	return sendViewportMsg(&vp);
}

// Moves the viewport up
int viewportUp() {
	if(vp.ty < VPYPIXELS)
		return VPRANGE;
	vp.ty -= VPYPIXELS;
	vp.by -= VPYPIXELS;
	return sendViewportMsg(&vp);
}

