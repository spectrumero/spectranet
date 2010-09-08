/* zcc +zx -lndos -lsplib2 -llibsocket -create-app astg.c  */


#include <stdio.h>
#include <spritepack.h>
#include <sound.h>
#include <string.h>

#include <sys/socket.h>		/* socket, connect, send, recv etc. */
#include <sys/types.h>		/* types, such as socklen_t */
#include <netdb.h>		/* gethostbyname */

extern struct sp_Rect *sp_ClipStruct;
#asm
LIB SPCClipStruct
._sp_ClipStruct         defw SPCClipStruct
#endasm
#pragma output STACKPTR=61440

/* Initial State of Print String Struct */
struct sp_Rect r = {0,0,24,32};        /* Bound Rect @ (8,8) height=8, width=24 */

struct sp_PSS psmenu = {
   0,                                  /* Illegal C to put '&r' directly here */
   sp_PSS_INVALIDATE | sp_PSS_XWRAP,   /* Invalidate Mode, X Wrap */
   0,                                  /* X = 0 */
   0,                                  /* Y = 0 */
   INK_WHITE | PAPER_BLACK,             /* Attribute = WHITE ON BLACK */
   0,                                  /* reserved */
   0,                                  /* reserved */
   0                                   /* reserved */
};

struct sp_PSS psbrd = {
   0,                                  /* Illegal C to put '&r' directly here */
   sp_PSS_INVALIDATE | sp_PSS_XWRAP,   /* Invalidate Mode, X Wrap */
   0,                                  /* X = 0 */
   0,                                  /* Y = 0 */
   INK_BLUE | PAPER_BLACK,             /* Attribute = WHITE ON BLACK */
   0,                                  /* reserved */
   0,                                  /* reserved */
   0                                   /* reserved */
};


uchar dep[33];                          /* String for debug */

extern uchar data[];
extern uchar netb[];
extern uchar  UDGstart[];

/* Sprites */

extern uchar tankp1[];   /*Player 1 Tank */
extern uchar tankp2[];   /*Player 2 Tank */
extern uchar bullet[];   /*Player 1&2 Bullets */

struct sp_SS *sp_tankp1;
struct sp_SS *sp_tankp2;
struct sp_SS *sp_bullet[6];

#define POSP1 0
#define POSP2 2
#define BULLETP1 4
#define BULLETP2 10
#define SCORE 16
#define BLOCK 18
#define EXP_TEST 0
#define EXP_BARRIER 1
#define EXP_PLAYER 2
#deinfe EXP_GAMEOVER 3
#define HOST 1
#define CLIENT 2
#define NETB_LEN 18


 uint PlayerRolle;   /* 1 Host -> Player 1 , 2 Client -> Player 2 */
 uint keyp1_dcha;
 uint keyp1_izq;
 uint keyp1_fire;
 uint keyp2_dcha;
 uint keyp2_izq;
 uint keyp2_fire;
 uchar winner;

 int sockfd;
 int listenfd;

/* Network Functions  */

/***************************************************************************************************/
/*
This function does all the necessary to establish the connection
*/
void Start_Match(uint linedo)

{
	struct sockaddr_in my_addr;
	struct hostent *he;

	/* Set up the sockaddr_in structure.
	 * Note that we ought to zero out the structure so
	 * any fields we don't explicitly set are set to 0. */
	memset(&my_addr, 0, sizeof(my_addr));

	// linedo = 1 Host
	// linedo = 2 Client 

	if (linedo == HOST)
	{							// Host Code
		/* Exercises for the reader:
		 * 1. Convert to UDP.
		 * 2. Convert to an asynchronous protocol (currently
		 *    the packet exchange is totally synchronous) */
		listenfd=socket(AF_INET, SOCK_STREAM, 0);
	
		my_addr.sin_family=AF_INET;
		my_addr.sin_port=htons(2020);

		if(bind(listenfd, &my_addr, sizeof(my_addr)) < 0)
		{
			printk("Bind failed\n");
			sockclose(listenfd);
			return;
		}

		/* Now listen for an incoming connection. */
		if(listen(listenfd, 1) < 0)
		{
			printk("Listen failed\n");
			sockclose(listenfd);
			return;
		}

		/* Wait for the client end to connect */
		if((sockfd=accept(listenfd, NULL, NULL)) < 0)
		{
			printk("Accept failed\n");
			sockclose(sockfd);
			sockclose(listenfd);
			return;
		}
	
	}
	else // linedo == CLIENT
	{							// Client Code
		he=gethostbyname("172.16.0.42");
		if(!he)
		{
			printk("Failed to look up remote host\n");
			return;
		}

		sockfd=socket(AF_INET, SOCK_STREAM, 0);
		if(sockfd < 0)
		{
			printk("Unable to open the socket\n");
			return;
		}

		my_addr.sin_port=htons(2020);
		my_addr.sin_addr.s_addr=he->h_addr;
		if(connect(sockfd, &my_addr, sizeof(sockaddr_in)) < 0)
		{
			printk("connect failed\n");
			sockclose(sockfd);
			return;
		}
	}

}
/*
This function exchange 18 bytes packet of global variables beetween player to times
one time for player 1 data
another time for player2 data
*/
void TxRxData(uint linedo)

{
	int bytes;

	/* First Player1 (Host) send is data      : Send
	   Second waits for Player2 (client) data : Receive
	   The protocol is deliberately simple to be an understandable
	   example. The reads will block if there's no data, generally
	   this would be undesirable, but for a LAN demonstration we
	   can get away with it.
	   Exercise for the reader:
	   * Make the protocol asynchronous.
	   * Advanced exercise: compensate for lag :-)
	*/
	if (linedo == HOST)
	{							// Host Code
		bytes=send(sockfd, data, NETB_LEN, 0);
		bytes=recv(sockfd, netb, NETB_LEN, 0);
	}

	else // linedo == CLIENT
	{							// Client Code
		bytes=recv(sockfd, netb, NETB_LEN, 0);
		bytes=send(sockfd, data, NETB_LEN, 0);
	}

}
/*
This function close the connection, ending the socket

*/
void End_Match(uint linedo)

{
	sockclose(sockfd);

	if (linedo == HOST)
	{							// Host Code
		sockclose(listenfd);
	}
}


/***************************************************************************************************/

void Init_data()
{

uchar i;
/* Init game strcuts */

// Bullets
for (i=0;i<6;i++)
{
	data[BULLETP1+i+i] = 255;
}
// Score

	data[SCORE]=0;
	data[SCORE+1]=0;
// Player Position

	data[POSP1]=2;
	data[POSP1+1]=9;
	data[POSP2]=21;
	data[POSP2+1]=14;
	
winner=0;
}

void Play_Sound(uint i)
{
 
 return;
 switch (i)
 
	 {
	 	 case EXP_TEST:
		 {
			//bit_fx(7);
			break;
		 }
	 case EXP_BARRIER:
		 {
			//bit_fx(0);
			break;
		 }
	 case EXP_PLAYER:
		 {
			//bit_fx(4);
			break;
		 }
	 case 3:
		 {
			//bit_fx(5);
			break;
		 }	 
	 default:
		 {
			break;
		 }
		 
	 
	 }
 
 sp_Border(BLACK);

}

void draw_score()

{
   sprintf(dep,"\x16\x04\x1c\x10\x03%01u",data[SCORE]);
   sp_PrintString(&psmenu,dep);
   sprintf(dep,"\x16\x13\x1c\x10\x06%01u",data[SCORE+1]);
   sp_PrintString(&psmenu,dep);

}


void show_num(uint n)

{
   sprintf(dep,"\x16\x04\x19\x10\x07%05u",n);
   sp_PrintString(&psmenu,dep);
   sp_UpdateNow();

}

void fire_bullet(uint idplayer)
{
    uint bpointer, ppointer;
    uchar i,j;
	uchar tmp[16];

    /* Select bullet struct according player role */
    if (idplayer==1)
    {
         bpointer = BULLETP1;
         ppointer = POSP1;


    }
    else
    {
        bpointer = BULLETP2;
        ppointer = POSP2;
    }

    i = 0;

    while (i<3)
    {
		j=bpointer +i + i;
        if (data[j] == 255)  /* Search a remaining bullet */
        {
            data[j+1]=data[ppointer+1] ;  /* Same column */
            if (idplayer==1)
            {
                 data[j]=data[ppointer] +1; /* store row */
            }
            else
			{
                data[j]=data[ppointer] -1; /* store row */
            }

            i = 3;
        }

        i++;
    }





}

/* No me convence la solución para el bucle pero parece que funciona. El marcador es la columna = 255
Habrá que repasarlo*/
void draW_currFrame()
{

      uint n,row,col;
  
/* Update sprites: tanks and bullets
     tile objects are updated in  */

/* Tanks */

	  sp_MoveSprAbs(sp_tankp1, sp_ClipStruct, 0, data[POSP1], data[POSP1+1], 0, 0);
	  sp_MoveSprAbs(sp_tankp2, sp_ClipStruct, 0, data[POSP2], data[POSP2+1], 0, 0);

/* Bullets */

      for (n = 0; n < 6; n++)
      {
	    row = n+n;
		col = row++;
		if (data[BULLETP1+col]!=255)
		{
		sp_MoveSprAbs(sp_bullet[n], sp_ClipStruct, 0,data[BULLETP1+col], data[BULLETP1+row], 0, 0);
		//sp_PrintAtInv(0, n+1, INK_MAGENTA | PAPER_BLACK, ' ');
		}
		else
		{
		//sp_PrintAtInv(0, n+1, INK_MAGENTA | PAPER_BLACK,0x83);
		}
	  }
	/* Score */
	draw_score();
     #asm
     halt
	 halt
	 halt
     #endasm
	  sp_UpdateNow();

}

void read_keys()
{


switch (PlayerRolle)
{
    case 1:
    {
        if (sp_KeyPressed(keyp1_dcha)) {

        if (data[POSP1+1]<22){
		data[POSP1+1]++;
        }
		}
        else if (sp_KeyPressed(keyp1_izq)) {

        if (data[POSP1+1]>1){
		data[POSP1+1]--;
        }
		}
        else if (sp_KeyPressed(keyp1_fire)) {
                fire_bullet(1);

        }
        break;
    }
    case 2:
    {
                if (sp_KeyPressed(keyp2_dcha)) {

        if (data[POSP2+1]<22){
		data[POSP2+1]++;
		}
        }
        else if (sp_KeyPressed(keyp2_izq)) {

        if (data[POSP2+1]>1){
		data[POSP2+1]--;
		}
        }
        else if (sp_KeyPressed(keyp2_fire)) {
                fire_bullet(2);
        }

        break;
    }
}
}

void intercambia_info()
{

uchar i;
uchar bpointer,ppointer,spointer;


   TxRxData(PlayerRolle);    // Exchange_info Through the network

   if (PlayerRolle==1)
    {
         bpointer = BULLETP2;
         ppointer = POSP2;
		 spointer = SCORE+1;
    }
    else
    {
        bpointer = BULLETP1;
        ppointer = POSP1;
		spointer = SCORE;
    }

	// Retreive Bullets position

		for (i=0;i<6;i++)
		{
		    data[bpointer+i]=netb[bpointer+i];
		}

	// Retreive Player position
	
		data[ppointer]=netb[ppointer];
		data[ppointer+1]=netb[ppointer+1];
	
	// Retreive Player Score
		data[spointer]=netb[spointer];
}

void procesa_juego()
{
    uchar row,col;
    uchar n;

   /* Bullets movement */

      for (n = 0; n < 6; n++)
      {
	    row = n+n;
		col = row++;
		if (data[BULLETP1+col]!=255)
		{
             if ( (data[BULLETP1+col]==22) || (data[BULLETP1+col]==1) )
                  {
                      data[BULLETP1+col]= 255;
                      sp_MoveSprAbs(sp_bullet[n], sp_ClipStruct, 0,data[BULLETP1+col], data[BULLETP1+row], 0, 0);
                  }
             else {
                 if ((n < 3)&& (PlayerRolle == 1))
                 {data[BULLETP1+col]++;}
                 else if ( (n >= 3)&& (PlayerRolle == 2) )
                 {data[BULLETP1+col]--;}
                 }

		}
      }

}

void procesa_resultado()
{
    uint i;
	uint j,k,l;
    uchar row,col;
    uchar n;
/* Detecta colisiones */

      for (n = 0; n < 6; n++)
      {
	    row = n+n;
		col = row++;
		j = BULLETP1+col;
		k = BULLETP1+row;
		l=2; 
	      if (data[j]!=255)
            {   	
				i = sp_ScreenStr(data[j], data[k]);// BARRIER PAPER 0 INK VERDE 0X83 = 01155  
				/* Check Barriers */
				if (i == 1155)
				{
						 sp_PrintAtInv(data[j], data[k], INK_WHITE | PAPER_BLACK, ' ');
						 data[j]= 255;
						 sp_MoveSprAbs(sp_bullet[n], sp_ClipStruct, 0,data[j], data[k], 0, 0);
						 sp_UpdateNow();
						 Play_Sound(EXP_BARRIER);
				}
				/* Check Players */
				// Player1
				if ( (data[j]==data[POSP1]) && (data[k]==data[POSP1+1]) )
					{
						 data[j]= 255;
						 sp_MoveSprAbs(sp_bullet[n], sp_ClipStruct, 0,data[j], data[k], 0, 0);
						 data[SCORE+1]++;
						 Play_Sound(EXP_PLAYER);
					}
				// Player2
				if ( (data[j]==data[POSP2]) && (data[k]==data[POSP2+1]) )
					{
						 data[j]= 255;
						 sp_MoveSprAbs(sp_bullet[n], sp_ClipStruct, 0,data[j], data[k], 0, 0);
						 data[SCORE]++;
						 Play_Sound(EXP_PLAYER);
					}
            }
     }

 if (data[SCORE]==3)
	{ winner =1;}
 else if (data[SCORE+1]==3)
	{ winner =2;}
}

// *
void menu()
{


	uchar *l1menu ="\x16\x04\x07A Silly Tank Game";
	uchar *l2menu ="\x16\x08\x07\x10\x021.- Create Match";
	uchar *l3menu ="\x16\x0a\x07\x10\x062.- Join   Match";
	uchar *ltree ="\x16\x06\x07\x10\x04\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83\x83";
    uchar *lcred1 ="\x16\x0F\x02\x10\x07 The First SPECTRANET Game";
    uchar *lcred2 ="\x16\x11\x01\x10\x05(c) 2010 raceamiga & Winston";
    uchar *lcred3 ="\x16\x13\x01\x10\x03IV ZDP TaskaParty Lite SEP'10";

    uint  key1,key2;
    uint elige;


	psmenu.bounds = &r;
	key1 = sp_LookupKey('1');
	key2 = sp_LookupKey('2');
	elige = 0;

 	sp_UpdateNow();
	//sp_PrintString(&psmenu,l1menu);
	sp_PrintString(&psmenu,"\x16\x04\x07\x10\x02A ");
	sp_PrintString(&psmenu,"\x10\x06Silly ");
	sp_PrintString(&psmenu,"\x10\x04Tank ");
	sp_PrintString(&psmenu,"\x10\x05Game");
	ltree[1]=6;
	sp_PrintString(&psmenu,ltree);
	sp_PrintString(&psmenu,l2menu);
	sp_PrintString(&psmenu,l3menu);
	ltree[1]=12;
	sp_PrintString(&psmenu,ltree);
	sp_PrintString(&psmenu,lcred1);
	sp_PrintString(&psmenu,lcred2);
    sp_PrintString(&psmenu,lcred3);
	
	sp_UpdateNow();
	while (!elige) {

        if (sp_KeyPressed(key1)) {  /* Host   = 1 */
                PlayerRolle=1;
                elige = 1;
        }
        if (sp_KeyPressed(key2)) {  /* Client = 2 */
                PlayerRolle=2;
                elige = 1;
	}
	}
}


void run_game()
{

	  uint i,n;
	  uint key0;
	  


/* in-game screen tiles & Text */

	  uchar *lbrdh =  "\x16\x00\x00\x0e\x20\x85\x0f";
      uchar *lbrdv =  "\x16\x00\x00\x0e\x18\x85\x0b\x08\x0f";
	  uchar *ltank1 =  "\x16\x02\x19\x10\x07Guy 1";
	  uchar *ltank2 =  "\x16\x15\x19\x10\x07Guy 2";
	  uchar *ltxt1 ="\x16\x09\x19\x10\x02A";
	  uchar *ltxt2 ="\x16\x0a\x19\x10\x06Silly";
	  uchar *ltxt3 ="\x16\x0b\x1a\x10\x04Tank";
	  uchar *ltxt4 ="\x16\x0c\x1a\x10\x05Game";
	  uchar *ltxt5 ="\x16\x0e\x18\x10\x07ZDP2010";
	  uchar *lscore1 ="\x16\x04\x1a\x10\x03\x84=";
	  uchar *lscore2 ="\x16\x13\x1a\x10\x06\x84=";

	  key0 = sp_LookupKey('0');
/* Init in-game screen section:
		Borders,
		Barriers,
		Scores
		Credits
*/
	  Init_data();
	  sp_Initialize(INK_GREEN | PAPER_BLACK,' ');
      sp_Border(BLACK);
	  psbrd.bounds = &r;
	  lbrdh[1]=0;
	  lbrdh[2]=0;
	  lbrdh[4]=32;
	  
	  sp_PrintString(&psbrd,lbrdh);
	  lbrdh[1]=23;
	  sp_PrintString(&psbrd,lbrdh);
	  lbrdh[1]=6;
	  lbrdh[2]=23;
	  lbrdh[4]=8;
	  sp_PrintString(&psbrd,lbrdh);
	  lbrdh[1]=17;
	  sp_PrintString(&psbrd,lbrdh);
	  lbrdv[2]=0;
	  sp_PrintString(&psbrd,lbrdv);
	  lbrdv[2]=23;
	  sp_PrintString(&psbrd,lbrdv);
	  lbrdv[2]=31;
	  sp_PrintString(&psbrd,lbrdv);
	  sp_PrintString(&psbrd,ltank1);
	  sp_PrintString(&psbrd,ltank2);
	  sp_PrintString(&psbrd,ltxt1);
	  sp_PrintString(&psbrd,ltxt2);
	  sp_PrintString(&psbrd,ltxt3);
	  sp_PrintString(&psbrd,ltxt4);
	  sp_PrintString(&psbrd,ltxt5);
	  sp_PrintString(&psbrd,lscore1);
      sp_PrintString(&psbrd,lscore2);
      sp_UpdateNow();
	  i= 0;
      for (n = 0; n != 24; n=n+2)
      {
          sp_PrintAtInv(data[BLOCK+n], data[BLOCK+n+1], INK_GREEN | PAPER_BLACK, 0x83);   /*Blocks row 1 */
      }
	  sp_MoveSprAbs(sp_tankp1, sp_ClipStruct, 0, data[POSP1], data[POSP1+1], 0, 0);
	  sp_MoveSprAbs(sp_tankp1, sp_ClipStruct, 0, 2, 10, 0, 0);
	  sp_MoveSprAbs(sp_tankp2, sp_ClipStruct, 0, data[POSP2], data[POSP2+1], 0, 0);
	  sp_MoveSprAbs(sp_tankp2, sp_ClipStruct, 0, 21, 13, 0, 0);
	  sp_UpdateNow();


/* ASTG's main loop */

  winner = 0;	
  while(!winner)
	{

		
		read_keys();			/* Read local player keys */
		procesa_juego();    	/* Process local Game movements & bullets */
    	intercambia_info(); 	/* Exchange shared info beetwen players */
		procesa_resultado();    /* Process consolidate info */
        draW_currFrame();  	    /* Dump Current Frame */
   }

	
	sp_PrintString(&psbrd,"\x16\x09\x01\x10\x07                      ");
	sp_PrintString(&psbrd,"\x16\x0e\x01\x10\x07                      ");
	sp_PrintString(&psbrd,"\x16\x0b\x03\x10\x07G A M E   O V E R");
	sprintf(dep,"\x16\x0d\x05\x10\x07Guy %01u    WINS!",winner);
	sp_PrintString(&psbrd,"\x16\x06\x01\x10\x02                      ");
	sp_PrintString(&psbrd,dep);
	sp_PrintString(&psbrd,"\x16\x06\x00\x10\x01\x0e\x20\x85\x0f");
	sp_PrintString(&psbrd,"\x16\x11\x00\x10\x01\x0e\x20\x85\x0f");
	sp_UpdateNow();
	Play_Sound(3);
	
	winner=0;
	while (!winner)
	{
	
	if (sp_KeyPressed(key0)) winner=1;
	
	}

}


/* Create memory allocator for sprite routines */
void *my_malloc(uint bytes)
{
   return sp_BlockAlloc(0);
}
void *u_malloc = my_malloc;
void *u_free = sp_FreeBlock;



main()
{

   uchar *temp;
   uint i,n,k;

   /* Player 1 vars */

   uchar p1x,p1y;
   uchar p2x,p2y;

   /* Register Interrupt Service Routine */

   #asm
   di
   #endasm
   sp_InitIM2(0xf1f1);
   sp_CreateGenericISR(0xf1f1);
   #asm
   ei
   #endasm
   /* Sprite system : Up to 8 sprites of 8x8 pixels at the same time  */
   /*                       x2 Tanks                                  */
   /*                       x6 Bullets                                */
   sp_AddMemory(0, 16, 14, 60088);   /* Add memory for sprites system */

   /* Init keyboard reading */
	/* key assignements */
   keyp1_dcha = sp_LookupKey('w');
   keyp1_izq  = sp_LookupKey('q');
   keyp1_fire = sp_LookupKey('z');
   keyp2_dcha = sp_LookupKey('p');
   keyp2_izq  = sp_LookupKey('o');
   keyp2_fire = sp_LookupKey('m');
   /* Create UDG's */
   temp = UDGstart;
   for (n = 0x80; n != 0x89; n++, temp += 8)
      sp_TileArray(n, temp);
   /* Create sprites */
   sp_tankp1 = sp_CreateSpr(sp_LOAD_SPRITE , 1, tankp1, 1, MAGENTA);
   sp_tankp2 = sp_CreateSpr(sp_LOAD_SPRITE , 1, tankp2, 1, YELLOW);
   n=0;
      for (n = 0; n < 6; n++)
      {
		sp_bullet[n] = sp_CreateSpr(sp_LOAD_SPRITE , 1, bullet, 1, WHITE);
	  }
   
/* main loop*/
while (1)
	{
	/* Init screen */
		//bit_open();
		sp_Border(BLACK);
		sp_Initialize(INK_WHITE | PAPER_BLACK, ' ');
		menu();
		Start_Match(PlayerRolle);
		run_game();
		End_Match(PlayerRolle);
		//bit_close();
	}
}

/* Game Graphics Defined in Assembler
   Assembler labels are visible in C if they are declared 'extern' arrays. */

#asm
; Data Section
._data
; player1 ROW & COL
defb 2,9
; player2 ROW & COL
defb 21,14
; bullets player1  ROW & COL
defb 255,2,255,2,255,2
; bullets player2  ROW & COL
defb 255,2,255,2,255,2
; score player1 & player 2
defb 0,0
; Barriers  ROW & COL
defb 9,1, 14,2, 9,5, 14,6, 9,9, 14,10, 9,13, 14,14, 9,17, 14,18, 9,21, 14,22
; network buffer
._netb
; player1 ROW & COL
defb 0,0
; player2 ROW & COL
defb 0,0
; bullets player1  ROW & COL
defb 0,0,0,0,0,0
; bullets player2  ROW & COL
defb 0,0,0,0,0,0
; score player1 & player 2
defb 0,0


; Graphics Section

; ----- TILES SECTION
._UDGstart
; 0x80	/*Player 1 Tank*/
defb	0, 24, 24,126,126,255,255,255
; 0x81  /*Player 2 Tank*/
defb	255,255,255,126,126,24,24,0
; 0x82  /*Bullet*/
defb	0,  0, 24, 24, 24, 24,  0,  0
; 0x83	/*Green Block*/
defb	0,  0,126,255,255,126,  0,  0
; 0x84	/*Victory flag*/
defb	32, 48, 56, 60, 32, 32, 32, 320
; 0x85	/*upper-left-corner*/
defb	0,126,126,126,126,126,126,0
; 0x86	/*lower-left-corner*/
defb	0,126,126,126,126,126,126,0
; 0x87	/*upper-right-corner*/
defb	0,126,126,126,126,126,126,0
; 0x88	/*lower-right-corner*/
defb	0,126,126,126,126,126,126,0
; 0x89	/*vertical-corner*/
defb	0,126,126,126,126,126,126,0
; 0x8a	/*horizontal-corner*/
defb	0,126,126,126,126,126,126,0
; 0x8b	/*midle-up-corner*/
defb	0,126,126,126,126,126,126,0
; 0x8c	/*midle-up-corner*/
defb	0,126,126,126,126,126,126,0

; ------ SPRITES SECTION


._tankp2
defb	0,0, 24,0, 24,0,126,0,126,0,255,0,255,0,255,0
; 0x81  /*Player 2 Tank*/
._tankp1
defb	255,0,255,0,255,0,126,0,126,0,24,0,24,0,0,0
; 0x82  /*Bullet*/
._bullet
defb	0,0,  0,0, 24,0, 24,0, 24,0, 24,0,  0,0,  0,0



#endasm



