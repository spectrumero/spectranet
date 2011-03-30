#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>

char getChecksum(char *buf, unsigned short size);

int main(int argc, char **argv)
{
	FILE *infile, *outfile;
	unsigned short length;
	unsigned int start=0x8000;
	struct stat fileinfo;
	char header[20];
	char tzxhdr[6];
	char *buf;
	char istap=0;

	if(argc < 4 || argc > 5)
	{
		fprintf(stderr, "Usage: %s <tzx|tap> <infile> <outfile> [start-addr]\n", argv[0]);
		fprintf(stderr, "Default start address is 32768\n");
		printf("argc=%d\n",argc);
		exit(255);
	}
	if(argc == 5)
	{
		start=strtol(argv[4], NULL, 0);
		if(start > 65535)
		{
			fprintf(stderr,"Start address too large\n");
			exit(255);
		}
	}
	if(!strcmp(argv[1], "tap"))
	{
		printf("Creating TAP file: %s\n", argv[3]);
		istap=1;
	}
	else
	{
		printf("Creating TZX file: %s\n", argv[3]);
	}

	if(stat(argv[2], &fileinfo) < 0)
	{
		perror("stat");
		exit(255);
	}

	infile=fopen(argv[2], "rb");
	if(!infile)
	{
		perror("open for reading");
		exit(255);
	}

	outfile=fopen(argv[3], "wb");
	if(!outfile)
	{
		perror("open for writing");
		exit(255);
	}
	length=fileinfo.st_size;

	if(istap) {
		/* For tap, header is 0x13 bytes */
		fputc(0x13, outfile);
		fputc(0x00, outfile);
	} else {
		/* write the tzx header */
		fprintf(outfile, "ZXTape!\x1A\x01\x14");
	}

	/* create the Spectrum header */
	header[0]=0;	/* flag byte - header */
	header[1]=3;	/* CODE file */
	strcpy(&header[2], "data      ");	/* file name */
	
	/* little-endian size */
	header[12]=length % 256;
	header[13]=length / 256;
	header[14]=start & (0xFF);
	header[15]=(start >> 8) & (0xFF);
	header[16]=header[14];	 /* and again */
	header[17]=header[15];

	header[18]=getChecksum(header, 18);

	if(!istap)
	{
		/* create the tzx block */
		tzxhdr[0]=0x10;	/* standard block */
		tzxhdr[1]=0xE8;	/* pause of 1000ms */
		tzxhdr[2]=0x03;
		tzxhdr[3]=19;	/* 19 bytes to come */
		tzxhdr[4]=0;
		fwrite(tzxhdr, 1, 5, outfile);
	}
	fwrite(header, 1, 19, outfile);

	if(istap) {
		fputc((length + 2) % 256, outfile);
		fputc((length + 2) / 256, outfile);
	} 
	else
	{
		/* create the data block */
		/* tzx 0x10, as before */
		tzxhdr[3]=(length+2) % 256;
		tzxhdr[4]=(length+2) / 256;
		fwrite(tzxhdr, 1, 5, outfile);
	}

	/* write the ZX header */
	fputc(0xFF, outfile);

	buf=(char *)malloc(length+1);
	if(!buf)
	{
		perror("malloc");
		exit(255);
	}
	*buf=0xFF;

	fread(buf+1, 1, length, infile);
	fwrite(buf+1, 1, length, outfile);
	fputc(getChecksum(buf, length+1), outfile);

	fclose(outfile);
	fclose(infile);
	return 0;
}

char getChecksum(char *buf, unsigned short size)
{
	unsigned short i;
	char result=0;

	for(i=0; i<size; i++)
	{
		result ^= *buf;
		buf++;
	}
	return result;
}

	
