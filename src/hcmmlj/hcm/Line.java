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

	// 1�����ǂ�(�p������-->�啶���ɕϊ�)
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

	// �ǂވʒu��1�������߂�
	public void ungetChar()
	{
		if (reachedEOL) {
			reachedEOL = false;
		} else if (index > 0) {
			index--;
		}
	}

	// ���݈ʒu���琔�l��ǂ߂邩�ǂ�����Ԃ�
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

	// ���l��ǂ� (���isInt()�Ő��l�Ƃ��ēǂ߂邩�m�F���Ă�������)
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

	// �󔒕������X�L�b�v
	// �s���܂ŋ󔒕����������ꍇ�Aindex == len�ɂȂ�(�s����index)
	public void skipSpace()
	{
		for (; index < len; index++) {
			if (!Character.isWhitespace(str.charAt(index))) {
				break;
			}
		}
		return;
	}

	// �p�^�[���Ƀ}�b�`����Ȃ�true��Ԃ��A���̕�index��i�߂�
	public boolean matchPattern(String pat)
	{
		boolean r = false;

		if (str.substring(index).toUpperCase().startsWith(pat)) {
			index += pat.length();
			r = true;
		}
		return r;
	}

	// ���C���̂����A�܂��ǂ܂ꂸ�Ɏc���Ă��镔����Ԃ�
	public String getRemainder()
	{
		return str.substring(index);
	}
}
