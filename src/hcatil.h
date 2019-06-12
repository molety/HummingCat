/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    header file                                                     */

#ifndef _HCATIL_H_
#define _HCATIL_H_

#include <sys/indirect.h>
#include <sys/system.h>
#include <sys/types.h>

typedef struct {
	IL super;
	int (far *_hcat_calc_workarea_size)(unsigned n_slot, unsigned n_track);
	int (far *_hcat_init)(intvector_t far *drv_core, void far *workarea,
						  unsigned n_slot, unsigned n_track,
						  unsigned intrpt_freq, unsigned srambank);
	int (far *_hcat_release)(void);
	int (far *_hcat_chain_hook)(intvector_t far *next);
	void far *(far *_hcat_get_workarea)(void);
	int (far *_hcat_set_waveform)(unsigned num, void far *waveformdata);
	int (far *_hcat_set_ampenv)(unsigned num, void far *ampenvdata);
	int (far *_hcat_set_pchenv)(unsigned num, void far *pchenvdata);
	int (far *_hcat_assign_track)(unsigned slot, unsigned n_track);
	int (far *_hcat_set_score)(unsigned slot, void far *scoredata,
							   unsigned priority, unsigned immediate);
	int (far *_hcat_check_status)(unsigned slot);
	int (far *_hcat_play)(unsigned slot, unsigned mode);
	int (far *_hcat_continue)(unsigned slot, unsigned mode);
	int (far *_hcat_stop)(unsigned slot);
	int (far *_hcat_enable_output)(unsigned slot, unsigned track);
	int (far *_hcat_change_speed)(unsigned slot, unsigned speed);
	int (far *_hcat_change_mastervol)(unsigned slot, unsigned track,
									  unsigned mastervol);
	int (far *_hcat_start_cs)(void far *cs);
	int (far *_hcat_stop_cs)(void);
	int (far *_hcat_set_driver_mode)(unsigned func, unsigned param);
	int (far *_hcat_reserve1)(void);
	int (far *_hcat_reserve2)(void);
	int (far *_hcat_reserve3)(void);
	int (far *_hcat_reserve4)(void);
	int (far *_hcat_reserve5)(void);
} HcatIL;


extern HcatIL hcatIL;
#define HCAT_CALL				hcatIL.

#define hcat_calc_workarea_size	HCAT_CALL _hcat_calc_workarea_size
#define hcat_init				HCAT_CALL _hcat_init
#define hcat_release			HCAT_CALL _hcat_release
#define hcat_chain_hook			HCAT_CALL _hcat_chain_hook
#define hcat_get_workarea		HCAT_CALL _hcat_get_workarea
#define hcat_set_waveform		HCAT_CALL _hcat_set_waveform
#define hcat_set_ampenv			HCAT_CALL _hcat_set_ampenv
#define hcat_set_pchenv			HCAT_CALL _hcat_set_pchenv
#define hcat_assign_track		HCAT_CALL _hcat_assign_track
#define hcat_set_score			HCAT_CALL _hcat_set_score
#define hcat_check_status		HCAT_CALL _hcat_check_status
#define hcat_play				HCAT_CALL _hcat_play
#define hcat_continue			HCAT_CALL _hcat_continue
#define hcat_stop				HCAT_CALL _hcat_stop
#define hcat_enable_output		HCAT_CALL _hcat_enable_output
#define hcat_change_speed		HCAT_CALL _hcat_change_speed
#define hcat_change_mastervol	HCAT_CALL _hcat_change_mastervol
#define hcat_start_cs			HCAT_CALL _hcat_start_cs
#define hcat_stop_cs			HCAT_CALL _hcat_stop_cs
#define hcat_set_driver_mode	HCAT_CALL _hcat_set_driver_mode
#define hcat_reserve1			HCAT_CALL _hcat_reserve1
#define hcat_reserve2			HCAT_CALL _hcat_reserve2
#define hcat_reserve3			HCAT_CALL _hcat_reserve3
#define hcat_reserve4			HCAT_CALL _hcat_reserve4
#define hcat_reserve5			HCAT_CALL _hcat_reserve5

#define open_hcatil(hcatILp) (ilibIL->_open("@hcat", (IL far *)hcatILp))

#endif /* _HCATIL_H_ */
