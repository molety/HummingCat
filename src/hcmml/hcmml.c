/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    MML compiler                                                    */

#include <ctype.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hcmml.h"

struct Token *GenToken(void);
void DelTokenList(void);
struct WaveEnv *GenWaveForm(void);
void DelWaveFormList(void);
struct WaveEnv *GenAmpEnv(void);
void DelAmpEnvList(void);
struct WaveEnv *GenPchEnv(void);
void DelPchEnvList(void);
struct Score *GenScore(void);
void DelScoreList(void);
struct Track *GenTrack(void);
void WritePack(void);
void WriteWaveEnvChunk(struct ChunkHeader *header, struct WaveEnv *root);
void WriteScoreChunk(struct ChunkHeader *header, struct Score *root);
struct Line *ReadLine(void);

void *AllocMemory(size_t alloc_size);
void ErrorAbort(char *fmt, ...);
void Usage(void);

static struct Token tokenRoot = {NULL};
static struct Token *tokenList = &tokenRoot;
static struct WaveEnv waveformRoot = {NULL};
static struct WaveEnv *waveformList = &waveformRoot;
static struct WaveEnv ampenvRoot = {NULL};
static struct WaveEnv *ampenvList = &ampenvRoot;
static struct WaveEnv pchenvRoot = {NULL};
static struct WaveEnv *pchenvList = &pchenvRoot;
static struct Score scoreRoot = {NULL};
static struct Score *scoreList = &scoreRoot;
static struct PackHeader *packHeader = NULL;
static struct ChunkHeader *waveformChunkHeader = NULL;
static struct ChunkHeader *ampenvChunkHeader = NULL;
static struct ChunkHeader *pchenvChunkHeader = NULL;
static struct ChunkHeader *scoreChunkHeader = NULL;
static struct Line *linePtr = NULL;

static FILE *mml_Fp;

int main(int argc, char **argv) {
	char *mml_filename = NULL;
	char *out_filename = NULL;
	int i;

	/* コマンドラインオプションの解析 */
	for (i = 1; i < argc; i++) {
		if (argv[i][0] == '/') {
			switch (toupper(argv[i][1])) {
			  case 'I':
				/* resource IDの指定 */
				break;
			  default:
				Usage();
				break;
			}
		} else {
			if (mml_filename == NULL) {
				mml_filename = argv[i];
			} else {
				out_filename = argv[i];
			}
		}
	}
	if (mml_filename == NULL || out_filename == NULL) Usage();

	/* MMLファイルを開く */
	if ((mml_Fp = fopen(mml_filename, "r")) == NULL) {
		ErrorAbort("Can't open MML file\n");
	}

	linePtr = (struct Line *)AllocMemory(sizeof(struct Line) + LINE_SIZE);
	packHeader = (struct PackHeader *)
	  AllocMemory(sizeof(struct PackHeader) + COMMENT_SIZE);
	packHeader->comment[0] = '\0';

	/* コンパイルする */
	Compile();

	/* 出力ファイルを開く */
	FileOpen(out_filename);

	/* チャンクヘッダを作成する */
	waveformChunkHeader = MakeWaveEnvChunkHeader(&waveformRoot, 'W');
	ampenvChunkHeader = MakeWaveEnvChunkHeader(&ampenvRoot, 'A');
	pchenvChunkHeader = MakeWaveEnvChunkHeader(&pchenvRoot, 'P');
	MakeScoreHeader(&scoreRoot);
	scoreChunkHeader = MakeScoreChunkHeader(&scoreRoot, 'S');

	/* リソースパックファイルへ書き出す */
	WritePack();

	/* MML/出力リソースファイルを閉じる */
	fclose(mml_Fp);
	FileClose();

	/* メモリ解放 */
	DelWaveFormList();
	DelAmpEnvList();
	DelPchEnvList();
	DelScoreList();
	free(linePtr);
	free(packHeader);
	free(ampenvChunkHeader);
	free(pchenvChunkHeader);
	free(scoreChunkHeader);

	return 0;
}



/* リソースパックを書き出す */
void WritePack(void) {
	long pack_header_size = 0;
	long paragraph_offset = 0;

	if (scoreList == &scoreRoot) {
		ErrorAbort("No score\n");
	}

	packHeader->magic = RESID;
	packHeader->resource_type = HCATID;
	packHeader->resource_id = 0;

	packHeader->pack_ver = PACK_VER_ID;
	packHeader->compiler_ver = COMPILER_VER_ID;
	packHeader->intrpt_freq = 75;
	packHeader->reserve0 = 0;
	packHeader->waveform_chunk = 0;
	packHeader->ampenv_chunk = 0;
	packHeader->pchenv_chunk = 0;
	packHeader->score_chunk = 0;
	packHeader->env_interval = 1;
	packHeader->reserve1 = 0;
	packHeader->spk_scaling = 255;		/* 指定なしのとき255 */
	packHeader->reserve2 = 0;

	pack_header_size = sizeof(struct PackHeader)
	  + StrSize(packHeader->comment);
	paragraph_offset = ((pack_header_size + 15) >> 4);
	if (waveformChunkHeader != NULL) {
		packHeader->waveform_chunk = paragraph_offset;
		paragraph_offset += waveformChunkHeader->paragraph_size;
	}
	if (ampenvChunkHeader != NULL) {
		packHeader->ampenv_chunk = paragraph_offset;
		paragraph_offset += ampenvChunkHeader->paragraph_size;
	}
	if (pchenvChunkHeader != NULL) {
		packHeader->pchenv_chunk = paragraph_offset;
		paragraph_offset += pchenvChunkHeader->paragraph_size;
	}
	if (scoreChunkHeader != NULL) {
		packHeader->score_chunk = paragraph_offset;
		paragraph_offset += scoreChunkHeader->paragraph_size;
	}
	packHeader->paragraph_size = paragraph_offset;

	FileWriteBlock(packHeader, sizeof(struct PackHeader));
	FileWriteBlock(packHeader->comment, StrSize(packHeader->comment));
	FilePaddingToAlign(16);

	WriteWaveEnvChunk(waveformChunkHeader, &waveformRoot);
	WriteWaveEnvChunk(ampenvChunkHeader, &ampenvRoot);
	WriteWaveEnvChunk(pchenvChunkHeader, &pchenvRoot);
	WriteScoreChunk(scoreChunkHeader, &scoreRoot);
}



void WriteWaveEnvChunk(struct ChunkHeader *header, struct WaveEnv *root) {
	struct WaveEnv *p = root->link;

	if (header == NULL) return;

	FileWriteBlock(header, sizeof(struct ChunkHeader)
				   + sizeof(struct ChunkHeaderItem) * header->n_item);

	while (p != NULL) {
		FileWriteBlock(p->buf, (p->pos - p->top));
		FilePaddingToAlign(2);
		p = p->link;
	}
	FilePaddingToAlign(16);
}


void WriteScoreChunk(struct ChunkHeader *header, struct Score *root) {
	struct Score *p = root->link;
	int i;

	if (header == NULL) return;

	FileWriteBlock(header, sizeof(struct ChunkHeader)
				   + sizeof(struct ChunkHeaderItem) * header->n_item);

	while (p != NULL) {
		FileWriteBlock(&(p->header), sizeof(struct ScoreHeader)
					   + StrSize(p->header.comment));
		for (i = 0; i < 4; i++) {
			if (p->track[i] != NULL) {
				FileWriteBlock(p->track[i]->buf,
							   p->track[i]->pos - p->track[i]->top);
			}
		}
		FilePaddingToAlign(2);
		p = p->link;
	}
	FilePaddingToAlign(16);
}



/* MMLファイルを1行読む */
struct Line *ReadLine(void) {
	unsigned char *p;

	if (fgets((char *)linePtr->buf, LINE_SIZE, mml_Fp) == NULL) {
		return NULL;
	}

	p = linePtr->buf;
	while (*p++ != '\0') ;			/* 空文 */
	linePtr->bottom = p;
	linePtr->top = linePtr->buf;
	linePtr->pos = linePtr->buf;

	return linePtr;
}

struct Token *GenToken(void) {
	struct Token *p;

	p = (struct Token *)AllocMemory(sizeof(struct Token));
	tokenList->link = p;
	tokenList = p;
	p->link = NULL;
	return p;
}

void DelTokenList(void) {
	struct Token *p, *t;

	p = tokenRoot.link;
	while (p != NULL) {
		t = p->link;
		free(p);
		p = t;
	}

	tokenRoot.link = NULL;
	tokenList = &tokenRoot;
}

struct WaveEnv *GenWaveForm(void) {
	struct WaveEnv *p;

	p = (struct WaveEnv *)AllocMemory(sizeof(struct WaveEnv) + WAVEFORM_SIZE);
	waveformList->link = p;
	waveformList = p;
	p->link = NULL;
	p->top = p->buf;
	p->bottom = p->buf + WAVEFORM_SIZE;
	p->release = NULL;
	p->pos = p->buf;
	return p;
}

void DelWaveFormList(void) {
	struct WaveEnv *p, *t;

	p = waveformRoot.link;
	while (p != NULL) {
		t = p->link;
		free(p);
		p = t;
	}

	waveformRoot.link = NULL;
	waveformList = &waveformRoot;
}

struct WaveEnv *GenAmpEnv(void) {
	struct WaveEnv *p;

	p = (struct WaveEnv *)AllocMemory(sizeof(struct WaveEnv) + ENVELOPE_SIZE);
	ampenvList->link = p;
	ampenvList = p;
	p->link = NULL;
	p->top = p->buf;
	p->bottom = p->buf + ENVELOPE_SIZE;
	p->release = NULL;
	p->pos = p->buf;
	return p;
}

void DelAmpEnvList(void) {
	struct WaveEnv *p, *t;

	p = ampenvRoot.link;
	while (p != NULL) {
		t = p->link;
		free(p);
		p = t;
	}

	ampenvRoot.link = NULL;
	ampenvList = &ampenvRoot;
}

struct WaveEnv *GenPchEnv(void) {
	struct WaveEnv *p;

	p = (struct WaveEnv *)AllocMemory(sizeof(struct WaveEnv) + ENVELOPE_SIZE);
	pchenvList->link = p;
	pchenvList = p;
	p->link = NULL;
	p->top = p->buf;
	p->bottom = p->buf + ENVELOPE_SIZE;
	p->release = NULL;
	p->pos = p->buf;
	return p;
}

void DelPchEnvList(void) {
	struct WaveEnv *p, *t;

	p = pchenvRoot.link;
	while (p != NULL) {
		t = p->link;
		free(p);
		p = t;
	}

	pchenvRoot.link = NULL;
	pchenvList = &pchenvRoot;
}

struct Score *GenScore(void) {
	struct Score *p;

	p = (struct Score *)AllocMemory(sizeof(struct Score) + COMMENT_SIZE);
	scoreList->link = p;
	scoreList = p;
	p->link = NULL;
	p->track[0] = NULL;
	p->track[1] = NULL;
	p->track[2] = NULL;
	p->track[3] = NULL;
	p->header.comment[0] = '\0';
	return p;
}

void DelScoreList(void) {
	struct Score *p, *t;

	p = scoreRoot.link;
	while (p != NULL) {
		free(p->track[0]);
		free(p->track[1]);
		free(p->track[2]);
		free(p->track[3]);

		t = p->link;
		free(p);
		p = t;
	}

	scoreRoot.link = NULL;
	scoreList = &scoreRoot;
}

struct Track *GenTrack(void) {
	struct Track *p;

	p = (struct Track *)AllocMemory(sizeof(struct Track) + TRACK_SIZE);
	p->top = p->buf;
	p->bottom = p->buf + TRACK_SIZE;
	p->pos = p->buf;
	p->octave = DEFAULT_OCTAVE;
	p->default_len = DEFAULT_DEFAULT_LEN;
	p->loop_nest = 0;
	return p;
}

/* パックコメントを設定する */
int SetPackComment(unsigned char *str) {
}


/* メモリ確保 */
void *AllocMemory(size_t alloc_size) {
	void *p;

	p = malloc(alloc_size);
	if (p == NULL) ErrorAbort("@@@Memory not enough\n");

	return p;
}

/* エラー停止 */
void ErrorAbort(char *fmt, ...) {
	va_list ap;

	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);

	exit(1);
}

/* 使い方・バージョンの表示 */
void Usage(void) {
	printf("hcmml  MML compiler for 'Humming Cat' ver%x.%02x\n",
		   (COMPILER_VER_ID >> 8), (COMPILER_VER_ID & 0xff));
	printf("Usage: hcmml <mml_file> <out_file>\n");
//	printf("        /In : n = resource ID (0..32767)\n");

	exit(1);
}
