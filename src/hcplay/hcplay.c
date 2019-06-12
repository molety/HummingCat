/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    data player                                                     */

#include <sys/bios.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <bsvilwp.h>
#include "../bcat.h"
#include "../bchcat.h"
#include "../hcpack.h"

#define PLAYER_VERSION "0.03"

int find_respack(void);
int select_respack(int n_item);
void far *read_respack(int num);
void capture_screen(void);

static char cursor_shape[8];
static int bmpsaver_available = FALSE;

int main(int argc, char **argv) {
	int result = 0;
	unsigned st = 0;
	int i = 0;
	int key = 0;
	int quitted = 0;
	int paused = 0;
	int mastervol = 15;
	int speed = 16;
	int spk_scaling = 255;
	int n_respack, pack_num;
	struct ChunkHeader far *score_chunk_header = NULL;
	int n_score, score_index;
	void far *pack = NULL;

	BCMem_Init(3);
	text_screen_init();

	if (ilibIL->_open("@bmpsaver", (IL far *)&bsvIL) == E_FS_SUCCESS) {
		bmpsaver_available = TRUE;
	}

	text_get_fontdata(0x10, (void far *)cursor_shape);
	font_set_monodata(0, 1, cursor_shape);
	/* スプライト表示有効化 */
	st = display_status();
	display_control(st | 0x0004);
	sprite_set_range(0, 0);
	/* スプライト設定 */
	sprite_set_char(0, 0 + 0x2800);

	n_respack = find_respack();
	if (n_respack == 0) {
		text_put_string(0, 0, "No data");
		key_wait();
		return 0;
	} else if (n_respack == 1) {
		pack_num = 0;
	} else {
		pack_num = select_respack(n_respack);
		if (pack_num < 0) return 0;			// プログラム中断
	}
	pack = read_respack(pack_num);

	text_screen_init();

	BCHcat_Init();
	BCHcat_ExtractPack(pack);
	spk_scaling = ((struct PackHeader far *)pack)->spk_scaling;
	score_chunk_header = (struct ChunkHeader far *)
	  MK_FP(FP_SEG(pack) + ((struct PackHeader far *)pack)->score_chunk,
			FP_OFF(pack));
	n_score = score_chunk_header->n_item;
	score_index = 0;

	text_put_string(7, 0, "HCPLAY ver" PLAYER_VERSION);
	text_put_string(3, 2, "Play");
	text_put_string(3, 3, "Pause/Continue");
	text_put_string(3, 4, "Stop");
	text_put_string(3, 5, "Score              :");
	text_put_string(3, 6, "MasterVol (0..15)  :");
	text_put_string(3, 7, "Speed (1..16..256) :");
	text_put_string(3, 8, "Spk_Scaling (0..3) :");
	text_put_string(3, 9, "Quit");


	do {
		if (key & KEY_A) {
			switch (i) {
			  case 0:
				BCHcat_SetScore(0, score_chunk_header->item[score_index].number);
				BCHcat_Play(0);
				paused = 0;
				break;
			  case 1:
				if (paused) {
					BCHcat_Continue(0);
					paused = 0;
				} else {
					if (BCHcat_CheckStatus(0) >= 2) {
						BCHcat_Stop(0);
						paused = 1;
					}
				}
				break;
			  case 2:
				BCHcat_Stop(0);
				paused = 0;
				break;
			  case 3:
				break;
			  case 4:
				break;
			  case 5:
				break;
			  case 6:
				break;
			  case 7:
				quitted = 1;
				break;
			}
		} else {
			if (key & (KEY_X2 | KEY_X4)) {
				if (key & KEY_X2) {
					switch (i) {
					  case 3:
						score_index++;
						if (score_index > (n_score - 1)) score_index = 0;
						break;
					  case 4:
						mastervol++;
						if (mastervol > 15) mastervol = 15;
						BCHcat_ChangeMasterVol(0, 0x0f, mastervol);
						break;
					  case 5:
						speed++;
						if (speed > 256) speed = 256;
						BCHcat_ChangeSpeed(0, speed);
						break;
					  case 6:
						if (spk_scaling < 0 || spk_scaling > 3) {
							spk_scaling = 0;
						} else {
							spk_scaling++;
						}
						if (spk_scaling > 3) spk_scaling = 3;
						BCHcat_SetDriverMode(0, spk_scaling);
						break;
					}
				}
				if (key & KEY_X4) {
					switch (i) {
					  case 3:
						score_index--;
						if (score_index < 0) score_index = n_score - 1;
						break;
					  case 4:
						mastervol--;
						if (mastervol < 0) mastervol = 0;
						BCHcat_ChangeMasterVol(0, 0x0f, mastervol);
						break;
					  case 5:
						speed--;
						if (speed < 1) speed = 1;
						BCHcat_ChangeSpeed(0, speed);
						break;
					  case 6:
						if (spk_scaling < 0 || spk_scaling > 3) {
							spk_scaling = 3;
						} else {
							spk_scaling--;
						}
						if (spk_scaling < 0) spk_scaling = 0;
						BCHcat_SetDriverMode(0, spk_scaling);
						break;
					}
				}
			} else {
				if (key & KEY_X1) {
					i--;
					if (i < 0) i = 7;
				}
				if (key & KEY_X3) {
					i++;
					if (i > 7) i = 0;
				}
				if (key & KEY_Y2) {
					capture_screen();
				}
			}
		}
		sprite_set_location(0, 16, (i + 2) * 8);
		sprite_set_range(0, 1);
		text_put_numeric(23, 5, 3, NUM_ALIGN_RIGHT,
						 score_chunk_header->item[score_index].number);
		text_put_numeric(23, 6, 3, NUM_ALIGN_RIGHT, mastervol);
		text_put_numeric(23, 7, 3, NUM_ALIGN_RIGHT, speed);
		if (spk_scaling < 0 || spk_scaling > 3) {
			text_put_string(23, 8, " --");
		} else {
			text_put_numeric(23, 8, 3, NUM_ALIGN_RIGHT, spk_scaling);
		}
	} while (!quitted && ((key = key_wait()) & KEY_START) == 0);

	BCHcat_Release();
	return 0;
}


#define SEARCH_DIR "/ram0/"
#define MAX_SEARCH_NUM 10
#define RES_HEADER_SIZE 32

static struct stat statbuf;
static char respackname[MAX_SEARCH_NUM][MAXFNAME + 1];
static char fnamebuf[MAXFNAME * 3];		// 大きさは適当
static char readbuf[RES_HEADER_SIZE];

int find_respack(void) {
	int n_ent = nument(SEARCH_DIR);
	int fd;		// file descriptor
	int i;
	int n_item = 0;

	for (i = 0; i < n_ent; i++) {
		getent(SEARCH_DIR, i, &statbuf);
		if (statbuf.count != -1
			&& (statbuf.mode & (FMODE_DIR | FMODE_LINK)) == 0
			&& statbuf.len > RES_HEADER_SIZE) {
			strcpy(fnamebuf, SEARCH_DIR);
			strncat(fnamebuf, statbuf.name, MAXFNAME);
			if ((fd = open(fnamebuf, O_RDONLY, 0)) < 0) {
				continue;
			}
			if (read(fd, readbuf, RES_HEADER_SIZE) < 0) {
				close(fd);
				continue;
			}
			if (strncmp(readbuf, "FRHC", 4) != 0) {
				close(fd);
				continue;
			}
			close(fd);
			strncpy(respackname[n_item], statbuf.name, MAXFNAME);
			respackname[n_item][MAXFNAME] = '\0';
			n_item++;
		}
		if (n_item >= MAX_SEARCH_NUM) break;
	}
	return n_item;
}

int select_respack(int n_item) {
	int key = 0;
	int num = 0;
	int i;

	text_put_string(7, 0, "HCPLAY ver" PLAYER_VERSION);
	text_put_string(4, 1, "Resource pack select");
	for (i = 0; i < n_item; i++) {
		text_put_string(3, i + 3, respackname[i]);
	}

	do {
		if (key & KEY_START) {
			num = -1;
			break;
		} else {
			if (key & KEY_X1) {
				num--;
				if (num < 0) num = n_item - 1;
			}
			if (key & KEY_X3) {
				num++;
				if (num > (n_item - 1)) num = 0;
			}
			if (key & KEY_Y2) {
				capture_screen();
			}
		}
		sprite_set_location(0, 16, (num + 3) * 8);
		sprite_set_range(0, 1);
	} while (((key = key_wait()) & KEY_A) == 0);

	sprite_set_range(0, 0);
	return num;
}

void far *read_respack(int num) {
	FILE far *fp;
	void far *read_buf = NULL;
	long read_size = 0;
	int i, j;

	strcpy(fnamebuf, SEARCH_DIR);
	strcat(fnamebuf, respackname[num]);

	if ((fp = fopen(fnamebuf, "r")) == NULL) {
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

void capture_screen(void) {
	if (bmpsaver_available) {
		bs_set_target(KH_BS_SCREEN1 | KH_BS_SCREEN2 | KH_BS_SPRITE);
		bs_sprite_set_range(0, 1);
		bs_save_screen_xmodem("hcplay.bmp", 0, 0, 224, 144);
	}
}
