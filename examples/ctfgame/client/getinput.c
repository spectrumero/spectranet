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

// Input routines

#include <input.h>
#include <spectrum.h>
#include <stdio.h>

#include "ctf.h"
#include "ctfmessage.h"

struct in_UDK k;
uchar sentdirs;

void initInput() {
	k.fire = in_LookupKey('m');
	k.up = in_LookupKey('q');
	k.down = in_LookupKey('a');
	k.left = in_LookupKey('o');
	k.right = in_LookupKey('p');
	sentdirs=0;
}

// This function only sends the input message if inputs have
// changed.
void getInput() {
	uchar dirs;
	uchar msg[2];
	uchar moveflags;
	dirs=in_JoyKeyboard(&k);
	if(dirs != sentdirs) {
		sendControlMsg(dirs);
		sentdirs=dirs;
	}
}

