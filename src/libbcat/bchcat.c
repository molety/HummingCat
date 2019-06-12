/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    'Humming Cat' support functions                                 */

#include <sys/bios.h>
#include <sys/process.h>
#include <sys/service.h>
#include "../hcatil.h"
#include "../hcpack.h"
#include "../bchcat.h"

int g_BCHcat_DebugPrint = 0;

#define NORMFARPTR(p)	MK_FP((FP_SEG(p) + (FP_OFF(p) >> 4)), (FP_OFF(p) & 0x0f))

int BCHcat_Init(void);
int BCHcat_Release(void);
int BCHcat_ExtractPack(void far *pack);
int BCHcat_SetScore(unsigned slot, unsigned number);
int BCHcat_CheckStatus(unsigned slot);
int BCHcat_Play(unsigned slot);
int BCHcat_Continue(unsigned slot);
int BCHcat_Stop(unsigned slot);
int BCHcat_EnableOutput(unsigned slot, unsigned track);
int BCHcat_ChangeSpeed(unsigned slot, unsigned speed);
int BCHcat_ChangeMasterVol(unsigned slot, unsigned track,
						   unsigned mastervol);
int BCHcat_SetDriverMode(unsigned func, unsigned param);


static HcatIL hcatIL;
static intvector_t driverCore;
static intvector_t oldHook;
static char workArea[2048];
static struct PackHeader far *packPtr = NULL;
static struct ChunkHeader far *scoreChunkHeader = NULL;

int BCHcat_Init(void) {
	if (open_hcatil(&hcatIL) == E_FS_SUCCESS) {
		hcat_init((intvector_t far *)&driverCore,
				  (void far *)((long)((void far *)(&workArea[15])) & 0xfffffff0L),
				  2, 6, 75, pcb_get_srambank());

		/* 必要ならここでエンベロープ間隔やCS間隔を変更する */

		sys_interrupt_set_hook(SYS_INT_VBLANK_COUNTUP,
							   (intvector_t far *)&driverCore,
							   (intvector_t far *)&oldHook);
	} else {
		return -1;
	}

	hcat_assign_track(0, 4);
	hcat_assign_track(1, 2);

	timer_enable(TIMER_VBLANK, TIMER_AUTOPRESET, 1);

	/* デバッグ用パラメータ表示 */
	if (g_BCHcat_DebugPrint) {
		text_put_numeric(20, 1, 4, 1, FP_SEG((void far *)workArea));
		text_put_numeric(20, 2, 4, 1, FP_OFF((void far *)workArea));
		text_put_numeric(20, 3, 4, 1, (int)driverCore.ds);
		text_put_numeric(20, 4, 4, 1, (int)driverCore.callback);
	}

	return 0;
}

int BCHcat_Release(void) {
	timer_disable(TIMER_VBLANK);

	sys_interrupt_reset_hook(SYS_INT_VBLANK_COUNTUP,
							 (intvector_t far *)&oldHook);

	hcat_release();

	return 0;
}

int BCHcat_ExtractPack(void far *pack) {
	struct PackHeader far *p = NORMFARPTR(pack);
	struct ChunkHeader far *chunk_header = NULL;
	unsigned number, segment, offset;
	int i;

	if (p == NULL || p->magic != RESID || p->resource_type != HCATID) {
		return -1;
	}

	if (p->waveform_chunk != 0) {
		chunk_header = MK_FP((FP_SEG(p) + p->waveform_chunk), FP_OFF(p));
		for (i = 0; i < chunk_header->n_item; i++) {
			number = chunk_header->item[i].number;
			segment = FP_SEG(chunk_header) + chunk_header->item[i].ptr_u;
			offset = FP_OFF(chunk_header) + chunk_header->item[i].ptr_l;
			if (hcat_set_waveform(number, MK_FP(segment, offset)) < 0) {
				return -1;
			}
		}
	}
	if (p->ampenv_chunk != 0) {
		chunk_header = MK_FP((FP_SEG(p) + p->ampenv_chunk), FP_OFF(p));
		for (i = 0; i < chunk_header->n_item; i++) {
			number = chunk_header->item[i].number;
			segment = FP_SEG(chunk_header) + chunk_header->item[i].ptr_u;
			offset = FP_OFF(chunk_header) + chunk_header->item[i].ptr_l;
			if (hcat_set_ampenv(number, MK_FP(segment, offset)) < 0) {
				return -1;
			}
		}
	}
	if (p->pchenv_chunk != 0) {
		chunk_header = MK_FP((FP_SEG(p) + p->pchenv_chunk), FP_OFF(p));
		for (i = 0; i < chunk_header->n_item; i++) {
			number = chunk_header->item[i].number;
			segment = FP_SEG(chunk_header) + chunk_header->item[i].ptr_u;
			offset = FP_OFF(chunk_header) + chunk_header->item[i].ptr_l;
			if (hcat_set_pchenv(number, MK_FP(segment, offset)) < 0) {
				return -1;
			}
		}
	}

	if (p->spk_scaling != 255) {
		hcat_set_driver_mode(0, p->spk_scaling);
	}

	packPtr = p;
	if (p->score_chunk != 0) {
		scoreChunkHeader = MK_FP((FP_SEG(p) + p->score_chunk), FP_OFF(p));
	}
	return 0;
}

int BCHcat_SetScore(unsigned slot, unsigned number) {
	int i;
	unsigned segment, offset;

	if (scoreChunkHeader == NULL) return -1;

	for (i = 0; i < scoreChunkHeader->n_item; i++) {
		if (scoreChunkHeader->item[i].number == number) {
			break;
		}
	}
	if (i >= scoreChunkHeader->n_item) return -1;

	segment = FP_SEG(scoreChunkHeader) + scoreChunkHeader->item[i].ptr_u;
	offset = FP_OFF(scoreChunkHeader) + scoreChunkHeader->item[i].ptr_l;

	return hcat_set_score(slot, MK_FP(segment, offset), 0, 0);
}

int BCHcat_CheckStatus(unsigned slot) {
	return hcat_check_status(slot);
}

int BCHcat_Play(unsigned slot) {
	return hcat_play(slot, 1);
}

int BCHcat_Continue(unsigned slot) {
	return hcat_continue(slot, 1);
}

int BCHcat_Stop(unsigned slot) {
	return hcat_stop(slot);
}

int BCHcat_EnableOutput(unsigned slot, unsigned track) {
	return hcat_enable_output(slot, track);
}

int BCHcat_ChangeSpeed(unsigned slot, unsigned speed) {
	return hcat_change_speed(slot, speed);
}

int BCHcat_ChangeMasterVol(unsigned slot, unsigned track,
						   unsigned mastervol) {
	return hcat_change_mastervol(slot, track, mastervol);
}

int BCHcat_SetDriverMode(unsigned func, unsigned param) {
	return hcat_set_driver_mode(func, param);
}
