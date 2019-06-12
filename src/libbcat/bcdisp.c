/* Black Cat Library for WonderWitch                                  */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    display functions                                               */

#include <sys/bios.h>
#include <sys/libwwc.h>
#include "../bcat.h"

void BCDisp_Init(void) {
	int i;

	display_control(0);		/* •\Ž¦‚ð‚¢‚Á‚½‚ñoff‚É */
	lcd_set_segments(0);
	for (i = 0; i < 16; i++) {
		lcd_set_color(i, 0);
	}
	for (i = 0; i < 8; i++) {
		palette_set_color(i, 0);
	}
	sprite_set_range(0, 127);
	screen_set_scroll(SCREEN1, 0, 0);
	screen_set_scroll(SCREEN2, 0, 0);
	screen2_set_window(0, 0, 255, 255);
	sprite_set_window(0, 0, 255, 255);

	display_control(0);
}

struct bc_sprite {
	unsigned char x;
	unsigned char y;
	unsigned char width;
	unsigned char height;
	unsigned char data[0];
};
typedef struct bc_sprite BC_SPRITE;

void BCDisp_PutSprite() {
}
