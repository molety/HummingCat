/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    chunk making                                                    */

// #include <ctype.h>
// #include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "hcmml.h"

struct ChunkHeader *MakeWaveEnvChunkHeader(struct WaveEnv *root, int chunk_type);
struct ChunkHeader *MakeScoreChunkHeader(struct Score *root, int chunk_type);
void MakeScoreHeader(struct Score *root);
long StrSize(unsigned char *str);


/* 波形/音量エンベロープ/音程エンベロープのチャンクヘッダを作る */
/* アイテムが0個なら(=チャンクが不要なら)NULLを返す */
struct ChunkHeader *MakeWaveEnvChunkHeader(struct WaveEnv *root, int chunk_type) {
	struct ChunkHeader *header;
	struct WaveEnv *p = root->link;
	long chunk_header_size = 4;
	long chunk_body_size = 0;
	int n_item = 0;
	int i = 0;

	while (p != NULL) {
		p->size = p->pos - p->top;
		p->size = (p->size + 1) & ~1;

		chunk_header_size += 4;
		chunk_body_size += p->size;
		n_item++;
		p = p->link;
	}
	if (n_item == 0) return NULL;

	header = (struct ChunkHeader *)AllocMemory(chunk_header_size);
	header->type = (unsigned char)chunk_type;
	header->n_item = (unsigned char)n_item;
	header->paragraph_size =
	  (unsigned short)((chunk_header_size + chunk_body_size + 15) >> 4);

	p = root->link;
	chunk_body_size = 0;
	for (i = 0; i < n_item; i++, p = p->link) {
		header->item[i].number = (unsigned char)(p->number);
		header->item[i].ptr_l =
		  (unsigned char)((chunk_header_size + chunk_body_size) & 0x0f);
		header->item[i].ptr_u =
		  (unsigned short)((chunk_header_size + chunk_body_size) >> 4);
		chunk_body_size += p->size;
	}

	return header;
}

/* スコアのチャンクヘッダを作る */
/* アイテムが0個なら(=チャンクが不要なら)NULLを返す */
struct ChunkHeader *MakeScoreChunkHeader(struct Score *root, int chunk_type) {
	struct ChunkHeader *header;
	struct Score *p = root->link;
	long chunk_header_size = 4;
	long chunk_body_size = 0;
	int n_item = 0;
	int i, j;

	while (p != NULL) {
		p->size = 10 + StrSize(p->header.comment);
		for (j = 0; j < 4; j++) {
			if (p->track[j] == NULL) continue;
			p->size += p->track[j]->pos - p->track[j]->top;
		}
		p->size = (p->size + 1) & ~1;

		chunk_header_size += 4;
		chunk_body_size += p->size;
		n_item++;
		p = p->link;
	}
	if (n_item == 0) return NULL;

	header = (struct ChunkHeader *)AllocMemory(chunk_header_size);
	header->type = (unsigned char)chunk_type;
	header->n_item = (unsigned char)n_item;
	header->paragraph_size =
	  (unsigned short)((chunk_header_size + chunk_body_size + 15) >> 4);

	p = root->link;
	chunk_body_size = 0;
	for (i = 0; i < n_item; i++, p = p->link) {
		header->item[i].number = (unsigned char)(p->number);
		header->item[i].ptr_l =
		  (unsigned char)((chunk_header_size + chunk_body_size) & 0x0f);
		header->item[i].ptr_u =
		  (unsigned short)((chunk_header_size + chunk_body_size) >> 4);
		chunk_body_size += p->size;
	}

	return header;
}


void MakeScoreHeader(struct Score *root) {
	struct Score *p = root->link;
	long offset;
	int i;

	while (p != NULL) {
		p->header.n_track = 0;
		p->header.track_bit = 0;
		offset = sizeof(struct ScoreHeader) + StrSize(p->header.comment);

		for (i = 0; i < 4; i++) {
			if (p->track[i] != NULL) {
				p->header.n_track++;
				p->header.track_bit |= (1 << i);
				p->header.track_ptr[i] = (unsigned short)offset;
				offset += p->track[i]->pos - p->track[i]->top;
			} else {
				p->header.track_ptr[i] = 0;
			}
		}
		p = p->link;
	}
}

/* 文字列の長さ('\0'も含む) */
long StrSize(unsigned char *str) {
	unsigned char *p = str;
	long size = 0;

	while (*p != '\0') {
		size++;
		p++;
	}
	return (size + 1);
}
