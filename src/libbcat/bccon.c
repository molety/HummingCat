/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    console emulate functions                                       */

#include <stdio.h>
#include <sys/bios.h>
#include "../stdarg.h"
#include "../bcat.h"

#define TAB_COLUMN 8

static int conX = 0;
static int conY = 0;
static const int conWidth = 28;
static const int conHeight = 18;
static char printfBuf[128];

static void BCCon_NewLine(void) {
	conX = 0;
	conY++;
	if (conY >= conHeight) conY = 0;
}

int BCCon_Init(void) {

	text_screen_init();
	conX = 0;
	conY = 0;

#if 0			/* テキストBIOSを使わない実装に変更するための布石 */
	int i;
	static char ank_font_buf[128][8];

	for (i = 0; i < 128; i++) {
		text_get_fontdata(i, (void far *)ank_font_buf[i]);
	}
	font_set_monodata(0, 128, (void far *)ank_font_buf);
#endif

	return BCERR_OK;
}

int BCCon_CLS(void) {
	text_fill_char(0, 0, 32 * 32, ' ');
	conX = 0;
	conY = 0;

#if 0			/* テキストBIOSを使わない実装に変更するための布石 */
	/* 画面をスペースで埋める */
	screen_fill_char(SCREEN2, 0, 0, conWidth - 1, conHeight - 1, 0x20);
#endif

	return BCERR_OK;
}

int BCCon_Puts(char *str) {
	int len = 0;
	char *top = str;
	char *p = str;
	char c;
	int terminated = FALSE;

	do {
		switch ((c = *p++)) {
		  case '\0':
			text_put_substring(conX, conY, top, len);
			conX += len;
			terminated = TRUE;
			break;
		  case '\n':
			text_put_substring(conX, conY, top, len);
			BCCon_NewLine();
			top = p;
			len = 0;
			break;
		  case '\t':
			text_put_substring(conX, conY, top, len);
			conX += len;
			len = TAB_COLUMN - (conX % TAB_COLUMN);
			if (conX + len < conWidth) {
				text_fill_char(conX, conY, len, ' ');
				conX += len;
			} else {
				text_fill_char(conX, conY, conWidth - conX, ' ');
				BCCon_NewLine();
			}
			top = p;
			len = 0;
			break;
		  default:
			len++;
			if (conX + len >= conWidth) {
				text_put_substring(conX, conY, top, len);
				BCCon_NewLine();
				top = p;
				len = 0;
			}
			break;
		}
	} while (!terminated);

#if 0			/* テキストBIOSを使わない実装に変更するための布石 */
	while (str[i] != '\0') {				/* @@@うそコード */
		for (i = 0; i < conWidth; i++) {
			if (str[i] == '\0') {
				BCCon_PutLine(str, i);
			}
		}
	}
#endif

	return BCERR_OK;
}


int BCCon_Printf(char *str, ...) {
	va_list ap;

	va_start(ap, str);
	vsprintf(printfBuf, str, ap);
	va_end(ap);

	BCCon_Puts(printfBuf);
	return BCERR_OK;
}

int BCCon_PutLine(char *str, int len) {
#if 0
	screen_set_char(SCREEN2, 0, y, len, 1, (void far *)str);
#endif
}
