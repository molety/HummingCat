/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    file I/O                                                        */

#include <stdio.h>
// #include <stdlib.h>
#include "hcmml.h"

static FILE *out_Fp;
static long totalWrittenSize = 0;

/* �t�@�C�����J�� */
void FileOpen(char *filename) {
	if ((out_Fp = fopen(filename, "wb")) == NULL) {
		ErrorAbort("Can't open out-file\n");
	}
}

/* �t�@�C������� */
void FileClose(void) {
	fclose(out_Fp);
}

/* �u���b�N�������o�� */
void FileWriteBlock(void *block, long size) {
	if (fwrite(block, size, 1, out_Fp) != 1) {
		ErrorAbort("@@@File write error\n");
	}
	totalWrittenSize += size;
}

/* �A���C�������g�̂��߂Ƀp�f�B���O���� */
void FilePaddingToAlign(int align) {
	int padding_size = 0;
	int i;

	if ((totalWrittenSize % align) > 0) {
		padding_size = align - (totalWrittenSize % align);
	}
	for (i = 0; i < padding_size; i++) {
		if (fputc(0xcc, out_Fp) != 0xcc) {
			ErrorAbort("@@@File write error\n");
		}
	}
	totalWrittenSize += padding_size;
}
