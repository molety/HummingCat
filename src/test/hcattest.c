/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    IL call test                                                    */

#include <sys/bios.h>
#include <stdio.h>
#include "../bcat.h"
#include "../bchcat.h"

extern int g_BCHcat_DebugPrint;

void far *read_test_file(void);

int main(int argc, char **argv) {
	int result = 0;
	void far *pack = NULL;

	g_BCHcat_DebugPrint = 1;	/* BCHcatのデバッグ表示ON */

	text_screen_init();
	BCCon_Printf("\nStart\n");
	key_wait();

	result = BCMem_Init(3);
	BCCon_Printf("MemInit        %d\n", result);
	key_wait();

	pack = read_test_file();
	result = (pack != NULL) ? 0 : -1;
	BCCon_Printf("ReadFile       %d\n", result);
	key_wait();

	result = BCHcat_Init();
	BCCon_Printf("Init           %d\n", result);
	key_wait();

	result = BCHcat_ExtractPack(pack);
	BCCon_Printf("ExtractPack    %d\n", result);
	key_wait();

	result = BCHcat_SetScore(0, 0);
	BCCon_Printf("SetScore       %d\n", result);
	key_wait();

	result = BCHcat_CheckStatus(0);
	BCCon_Printf("CheckStatus1   %d\n", result);
	key_wait();

	result = BCHcat_Play(0);
	BCCon_Printf("Play           %d\n", result);
	key_wait();

	result = BCHcat_CheckStatus(0);
	BCCon_Printf("CheckStatus2   %d\n", result);
	key_wait();

	result = BCHcat_Release();
	BCCon_Printf("Release        %d\n", result);
	key_wait();

	return 0;
}

#define MML_FILENAME "/ram0/TEST.FR"

void far *read_test_file(void) {
	FILE far *fp;
	void far *read_buf = NULL;
	long read_size = 0;
	int i, j;

	if ((fp = fopen(MML_FILENAME, "r")) == NULL) {
		return NULL;
	}

	if (fseek(fp, 0, SEEK_END) != 0) {
		goto Error;
	}
	read_size = ftell(fp);
	rewind(fp);
	if (read_size > 32767L) {
		goto Error;
	}

	if ((read_buf = (void far *)BCMem_Alloc(read_size, 2)) == NULL) {
		goto Error;
	}

	if (fread(read_buf, read_size, 1, fp) != 1) {
		goto Error;
	}

	fclose(fp);
	return read_buf;

  Error:
	fclose(fp);
	return NULL;
}
