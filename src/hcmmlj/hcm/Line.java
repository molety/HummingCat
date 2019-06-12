/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - line                                                   */

package hcm;

public class Line
{
	private String str;
	private int len;
	private int index;
	private boolean reachedEOL;

	public Line(String s)
	{
		str = s;
		len = str.length();
		index = 0;
		reachedEOL = false;
	}

	public String toString()
	{
		return str + "[" + index + "]";
	}

	// 1文字読む(英小文字-->大文字に変換)
	public int getChar()
	{
		int c = -1;

		skipSpace();
		if (index < len) {
			c = (int)Character.toUpperCase(str.charAt(index++));
		} else {
			c = -1;
			reachedEOL = true;
		}
		return c;
	}

	// 読む位置を1文字分戻す
	public void ungetChar()
	{
		if (reachedEOL) {
			reachedEOL = false;
		} else if (index > 0) {
			index--;
		}
	}

	// 現在位置から数値を読めるかどうかを返す
	public boolean isInt()
	{
		boolean r = false;
		int i;

		skipSpace();
		i = index;
		if (i < len) {
			switch (str.charAt(i)) {
			  case '+':
			  case '-':
				i++;
				break;
			}
		}
		if (i < len) {
			if (Character.isDigit(str.charAt(i))) {
				r = true;
			}
		}
		return r;
	}

	// 数値を読む (先にisInt()で数値として読めるか確認しておくこと)
	public int getInt()
	{
		int c;
		int n = 0;
		int sign = 1;

		skipSpace();
		if (index < len) {
			switch (str.charAt(index)) {
			  case '+':
				sign = 1;
				index++;
				break;
			  case '-':
				sign = -1;
				index++;
				break;
			}
		}

		for (; index < len; index++) {
			if (Character.isDigit(str.charAt(index))) {
				n = n * 10 + Character.digit(str.charAt(index), 10);
			} else {
				break;
			}
		}
		return ((sign > 0) ? n : -n);
	}

	// 空白文字をスキップ
	// 行末まで空白文字だった場合、index == lenになる(不正なindex)
	public void skipSpace()
	{
		for (; index < len; index++) {
			if (!Character.isWhitespace(str.charAt(index))) {
				break;
			}
		}
		return;
	}

	// パターンにマッチするならtrueを返し、その分indexを進める
	public boolean matchPattern(String pat)
	{
		boolean r = false;

		if (str.substring(index).toUpperCase().startsWith(pat)) {
			index += pat.length();
			r = true;
		}
		return r;
	}

	// ラインのうち、まだ読まれずに残っている部分を返す
	public String getRemainder()
	{
		return str.substring(index);
	}
}
