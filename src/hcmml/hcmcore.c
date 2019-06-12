/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    MML compiler core                                               */

// #include <ctype.h>
// #include <stdio.h>
#include <stdlib.h>
// #include <string.h>
#include "hcmml.h"


#define ToUpper(c) (((c) >= 'a' && (c) <= 'z') ? (c) - 'a' + 'A' : (c))
#define IsDigit(c) ((c) >= '0' && (c) <= '9')

void Compile(void);
static void ParseWaveForm(struct WaveEnv *waveform, struct Line *line);
static void ParseAmpEnv(struct WaveEnv *ampenv, struct Line *line);
static void ParsePchEnv(struct WaveEnv *pchenv, struct Line *line);
static void ParseTrack(struct Track *track, struct Line *line);
static void AddTrackEnd(struct Score *score);
static void OutputNote(struct Track *track, int note, int abslen);
static void OutputByte(struct Track *track, unsigned char c);

static int noteTable[] = {9, 11, 0, 2, 4, 5, 7};



/* コンパイラ・コア */
void Compile(void) {
	unsigned char c;
	unsigned char *p;
	struct Line *line;
	struct Score *score;
	struct WaveEnv *waveform;
	struct WaveEnv *ampenv;
	struct WaveEnv *pchenv;
	int n;

	score = GenScore();
	score->number = 0;

	while ((line = ReadLine()) != NULL) {
		p = line->top;
		c = LexGetChar(&p);
		switch (c) {
		  case '\0':
		  case ';':
			break;
		  case '#':
			c = LexGetChar(&p);
			switch (c) {
			  case '0':
			  case '1':
			  case '2':
			  case '3':
				n = c - '0';
				if (score->track[n] == NULL) {
					score->track[n] = GenTrack();
				}
				line->pos = p;
				ParseTrack(score->track[n], line);
				break;
			  default:
				break;
			}
			break;
		  case '@':
			c = LexGetChar(&p);
			if (IsDigit(c)) {
				waveform = GenWaveForm();
				LexUngetChar(&p);
				waveform->number = LexGetNum(&p);
			} else {
				switch (c) {
				  case 'A':
					if ((n = LexGetNum(&p)) != GETNUMFAILED) {
						ampenv = GenAmpEnv();
						ampenv->number = n;
					}
					break;
				  case 'P':
					if ((n = LexGetNum(&p)) != GETNUMFAILED) {
						pchenv = GenPchEnv();
						pchenv->number = n;
					}
					break;
				  default:
					break;
				}
			}
			break;
		  case '$':
			break;
		  default:
			break;
		}
	}

	AddTrackEnd(score);
	return;
}


void ParseWaveForm(struct WaveEnv *waveform, struct Line *line) {
}

void ParseAmpEnv(struct WaveEnv *ampenv, struct Line *line) {
}

void ParsePchEnv(struct WaveEnv *pchenv, struct Line *line) {
}

/* Parser for Track data */
void ParseTrack(struct Track *track, struct Line *line) {
	struct Token *token;
	int attr;
	int abslen;
	int slur_count = 0;
	int i;
	int quoted = FALSE;

	token = GenToken();

	while ((attr = Lex(token, line)) != EOL) {
		switch (attr) {
		  case INVALID:
			ErrorAbort("Invalid MML\n");
			break;
		  case QUOTE:
			quoted = !quoted;
			break;
		  case NOTE:
			switch (token->u.note.len_flag) {
			  case 0:
				if (token->u.note.dot == 0) {
					abslen = -1;		/* デフォルト音長を使用 */
				} else {
					abslen = track->default_len;
					for (i = 0; i < token->u.note.dot; i++) {
						abslen += (track->default_len) >> (i + 1);
					}
				}
				break;
			  case 1:
				if (token->u.note.len == 0) {
					ErrorAbort("Can't use length 0\n");
				}
				abslen = 192 / token->u.note.len;
				for (i = 0; i < token->u.note.dot; i++) {
					abslen += (192 / token->u.note.len) >> (i + 1);
				}
				break;
			  case 2:
				abslen = token->u.note.len;
				for (i = 0; i < token->u.note.dot; i++) {
					abslen += (token->u.note.len) >> (i + 1);
				}
				break;
			}
			switch (token->u.note.name) {
			  case 'A':
			  case 'B':
			  case 'C':
			  case 'D':
			  case 'E':
			  case 'F':
			  case 'G':
				OutputNote(track, noteTable[token->u.note.name - 'A']
						   + token->u.note.accidental + ((track->octave - 1) * 12), abslen);
				break;
			  case 'R':
				OutputNote(track, 0, abslen);
				break;
			  case 'W':
				OutputNote(track, 1, abslen);
				break;
			  case 'L':
				if (abslen < 0 || abslen > 255) {
					ErrorAbort("Invalid parameter(Ln)\n");
				}
				track->default_len = abslen;
				OutputByte(track, 0xc1);
				OutputByte(track, abslen);
				break;
			}
			break;
		  case COMMAND0:
			switch (token->u.command.name) {
			  case '<':
				track->octave--;
				if (track->octave < 1) ErrorAbort("Too low octave\n");
				break;
			  case '>':
				track->octave++;
				if (track->octave > 8) ErrorAbort("Too high octave\n");
				break;
			}
			break;
		  case COMMAND1:
			switch (token->u.command.name) {
			  case 'O':
				track->octave = token->u.command.param;
				if (track->octave < 1 || track->octave > 8) {
					ErrorAbort("Invalid parameter(On)\n");
				}
				break;
			  case 'T':
				OutputByte(track, 0xc0);
				OutputByte(track, token->u.command.param & 0xff);
				OutputByte(track, token->u.command.param >> 8);
				break;
			  case 'Q':
				OutputByte(track, 0xc2 + token->u.command.param);
				break;
			  case 'V':
				OutputByte(track, 0xcb + token->u.command.param);
				break;
			  case '\\':
				OutputByte(track, 0xe0);
				OutputByte(track, token->u.command.param & 0xff);
				OutputByte(track, token->u.command.param >> 8);
				break;
			  case 'S':
				OutputByte(track, 0xe2);
				OutputByte(track, token->u.command.param & 0xff);
				OutputByte(track, token->u.command.param >> 8);
				break;
			}
			break;
		  case COMMAND2:
			break;
		  case SLUR:
			slur_count++;
			break;
		  case LOOP_TOP:
		  case LOOP_BOTTOM:
		  case LOOP_EXIT:
			ErrorAbort("Not supported yet!\n");
			break;
		  default:
			ErrorAbort("Internal error (Unknown status)\n");
			break;
		}
	}
	//    OutputNote();	/* バッファにたまった分を吐き出す */

	DelTokenList();
	return;
}

/* スコアデータにトラック終端コードを追加する */
void AddTrackEnd(struct Score *score) {
	struct Score *p = score;
	int i;

	if (p == NULL) return;

	for (i = 0; i < 4; i++) {
		if (p->track[i] != NULL) {
			OutputByte(p->track[i], 0xff);
		}
	}
}

/* 音符の出力 */
void OutputNote(struct Track *track, int note, int abslen) {
	if (abslen < 0) {
		OutputByte(track, note << 1);
	} else {
		OutputByte(track, (note << 1) | 0x01);
		if (abslen < 240) {
			OutputByte(track, abslen);
		} else {
			OutputByte(track, ((abslen >> 8) & 0x0f) | 0xf0);
			OutputByte(track, abslen & 0xff);
		}
	}
	return;
}

void OutputByte(struct Track *track, unsigned char c) {
	*(track->pos) = c;
	track->pos++;
}
