/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    resource pack structure definition                              */

#ifndef _HCPACK_H_
#define _HCPACK_H_

#define PACK_VER_ID  0x0002

/* 'Humming Cat' resource pack header */
#ifndef RESID
#define RESID	0x5246				/* 'FR' */
#endif
#define HCATID	0x4348				/* 'HC' */

struct PackHeader {
	unsigned short magic;			/* "FR" */
	unsigned short resource_type;	/* "HC" */
	unsigned short paragraph_size;	/* resource 'para' size (include header) */
	short resource_id;				/* resource ID */

	unsigned short pack_ver;
	unsigned short compiler_ver;
	unsigned short intrpt_freq;
	unsigned short reserve0;
	unsigned short waveform_chunk;
	unsigned short ampenv_chunk;
	unsigned short pchenv_chunk;
	unsigned short score_chunk;
	unsigned short env_interval;
	unsigned short reserve1;
	unsigned char spk_scaling;
	unsigned char reserve2;
	unsigned char comment[0];
};

struct ChunkHeaderItem {
	unsigned char number;
	unsigned char ptr_l;
	unsigned short ptr_u;
};

struct ChunkHeader {
	unsigned char type;
	unsigned char n_item;
	unsigned short paragraph_size;
	struct ChunkHeaderItem item[0];
};

struct ScoreHeader {
	unsigned char n_track;
	unsigned char track_bit;
	unsigned short track_ptr[4];
	unsigned char comment[0];
};

#endif /* _HCPACK_H_ */
