/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    MML compiler header                                             */

#ifndef _HCMML_H_
#define _HCMML_H_

#include "../hcpack.h"

#define COMPILER_VER_ID 0x0005		/* 0xUULL -> ver UU.LL */

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif

enum SYMBOL {
	EOL,
	INVALID,
	QUOTE,
	NOTE,
	COMMAND0,
	COMMAND1,
	COMMAND2,
	SLUR,
	PORTAMENTO,
	LOOP_TOP,
	LOOP_BOTTOM,
	LOOP_EXIT
};


#define COMMENT_SIZE 256		/* for Pack & Score */

#define WAVEFORM_SIZE 16
#define ENVELOPE_SIZE 256
struct WaveEnv {
	struct WaveEnv *link;
	int number;
	long size;
	unsigned char *top;
	unsigned char *bottom;
	unsigned char *release;
	unsigned char *pos;
	unsigned char buf[0];
};

struct Score {
	struct Score *link;
	int number;
	long size;
	struct Track *track[4];
	struct ScoreHeader header;
};

#define TRACK_SIZE 1024
#define DEFAULT_OCTAVE 4
#define DEFAULT_DEFAULT_LEN 48
struct Track {
	unsigned char *top;
	unsigned char *bottom;
	unsigned char *pos;
	int octave;
	int default_len;
	int loop_nest;
	struct Token *token;
	unsigned char buf[0];
};


#define LINE_SIZE 256
struct Line {
	unsigned char *top;
	unsigned char *bottom;
	unsigned char *pos;
	unsigned char buf[0];
};


struct Note {
	int name;				/* 音名 */
	int accidental;			/* 臨時記号 */
	int len;				/* 長さ */
	int dot;				/* 付点 */
	int len_flag;			/* 0:指定なし 1:音長 2:絶対音長 */
};

struct Command {
	int name;
	int name2;
	int param;
	int param2;
};

struct Token {
	struct Token *link;
	int attr;
	union {
		struct Note note;
		struct Command command;
	} u;
};


/* フロントエンド側で用意する関数 */
extern struct Token *GenToken(void);
extern void DelTokenList(void);
extern struct WaveEnv *GenWaveForm(void);
extern void DelWaveFormList(void);
extern struct WaveEnv *GenAmpEnv(void);
extern void DelAmpEnvList(void);
extern struct WaveEnv *GenPchEnv(void);
extern void DelPchEnvList(void);
extern struct Score *GenScore(void);
extern void DelScoreList(void);
extern struct Track *GenTrack(void);

extern struct Line *ReadLine(void);
extern void WritePack(void);
extern void ErrorAbort(char *fmt, ...);
extern void *AllocMemory(size_t alloc_size);

/* hcmcore.c */
extern void Compile(void);

/* hcmlex.c */
extern int Lex(struct Token *token, struct Line *line);
extern unsigned char LexGetChar(unsigned char **ptr);
extern void LexUngetChar(unsigned char **ptr);
extern long LexGetNum(unsigned char **ptr);
#define GETNUMFAILED 1000000		/* MMLで使用されない値にしておく */

/* hcmchunk.c */
extern struct ChunkHeader *MakeWaveEnvChunkHeader(struct WaveEnv *root, int chunk_type);
extern struct ChunkHeader *MakeScoreChunkHeader(struct Score *root, int chunk_type);
extern void MakeScoreHeader(struct Score *root);
extern long StrSize(unsigned char *str);

/* hcmfile.c */
extern void FileOpen(char *filename);
extern void FileClose(void);
extern void FileWriteBlock(void *block, long size);
extern void FilePaddingToAlign(int align);

#endif /* _HCMML_H_ */
