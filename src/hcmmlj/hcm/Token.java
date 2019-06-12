/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - token                                                  */

package hcm;

public class Token
{
	public static final int INVALID = 0;
	public static final int EOL = 1;
	public static final int SHARP = 2;
	public static final int EQUAL = 3;
	public static final int QUOTE = 4;
	public static final int NOTE = 5;
	public static final int COMMAND0 = 6;
	public static final int COMMAND1 = 7;
	public static final int COMMAND2 = 8;
	public static final int SLUR = 9;
	public static final int PORTAMENTO = 10;
	public static final int LOOP_TOP = 11;
	public static final int LOOP_BOTTOM = 12;
	public static final int LOOP_EXIT = 13;

	// ç\ë¢ëÃÇ∆ÇµÇƒégÇ¢ÇΩÇ¢ÇæÇØÇ»ÇÃÇ≈publicÇ…ÇµÇΩ
	public int attr;
	public int name;
	public int name2;
	public int param;
	public int param2;
	public int accidental;
	public int len_flag;
	public int len;
	public int dot;

	public Token()
	{
		attr = INVALID;
		name = -1;
		name2 = -1;
		param = -1;
		param2 = -1;
		accidental = 0;
		len_flag = 0;
		len = 0;
		dot = 0;
	}
}
