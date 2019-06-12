/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - lexical analyzer                                       */

package hcm;

public class Lexer
{
	public static Token lexer(Line line)
	{
		int c;
		Token t = new Token();

		c = line.getChar();
	  lexmain:
		switch (c) {
		  case 'A':
		  case 'B':
		  case 'C':
		  case 'D':
		  case 'E':
		  case 'F':
		  case 'G':
		  case 'R':
		  case 'W':
		  case 'L':
		  case '^':
			t.name = c;
			c = line.getChar();
			while (c == '#' || c == '+' || c == '-') {
				switch (c) {
				  case '#':
				  case '+':
					t.accidental++;
					break;
				  case '-':
					t.accidental--;
					break;
				}
				c = line.getChar();
			}
			if (c != -1 && Character.isDigit((char)c)) {
				t.len_flag = 1;
				line.ungetChar();
				t.len = line.getInt();
				c = line.getChar();
			} else if (c == '%') {
				if (line.isInt()) {
					t.len_flag = 2;
					t.len = line.getInt();
					c = line.getChar();
				} else {
					t.attr = Token.INVALID;
					break lexmain;
				}
			}
			while (c == '.') {
				t.dot++;
				c = line.getChar();
			}
			line.ungetChar();
			t.attr = Token.NOTE;
			break;
		  case '<':
		  case '>':
		  case '{':
		  case '}':
		  case '(':
		  case ')':
		  case '|':
		  case '`':
		  case '*':
		  case '!':
			t.name = c;
			t.attr = Token.COMMAND0;
			break;
		  case 'O':
		  case 'T':
		  case 'Q':
		  case 'K':
			t.name = c;
			if (line.isInt()) {
				t.param = line.getInt();
			} else {
				t.attr = Token.INVALID;
				break lexmain;
			}
			t.attr = Token.COMMAND1;
			break;
		  case 'V':
		  case 'P':
		  case '\\':
		  case 'S':
			t.name = c;
			if ((c = line.getChar()) == '~') {
				t.name2 = c;
			} else {
				line.ungetChar();
			}
			if (line.isInt()) {
				t.param = line.getInt();
			} else {
				t.attr = Token.INVALID;
				break lexmain;
			}
			t.attr = Token.COMMAND1;
			break;
		  case '@':
			t.name = c;
			c = line.getChar();
			if (c == 'S') {
				t.name2 = c;
				if (line.isInt()) {
					t.param = line.getInt();
				} else {
					t.attr = Token.INVALID;
					break lexmain;
				}
				if (line.getChar() == ','
					&& line.isInt()) {
					t.param2 = line.getInt();
				} else {
					t.attr = Token.INVALID;
					break lexmain;
				}
				t.attr = Token.COMMAND2;
			} else {
				switch (c) {
				  case 'N':
				  case 'A':
				  case 'P':
					t.name2 = c;
					break;
				  default:
					line.ungetChar();
					break;
				}
				if (line.isInt()) {
					t.param = line.getInt();
				} else {
					t.attr = Token.INVALID;
					break lexmain;
				}
				t.attr = Token.COMMAND1;
			}
			break;
		  case '&':
			t.attr = Token.SLUR;
			break;
		  case '_':
			t.attr = Token.PORTAMENTO;
			break;
		  case '[':
			if (line.isInt()) {
				t.param = line.getInt();
			} else {
				t.param = 2;
			}
			t.attr = Token.LOOP_TOP;
			break;
		  case ']':
			t.attr = Token.LOOP_BOTTOM;
			break;
		  case '/':
			t.attr = Token.LOOP_EXIT;
			break;
		  case '#':
			t.attr = Token.SHARP;
			break;
		  case '=':
			t.attr = Token.EQUAL;
			break;
		  case '\"':
			t.attr = Token.QUOTE;
			break;
		  default:
			if (c == ';' || c == -1) {
				t.attr = Token.EOL;
			} else {
				t.attr = Token.INVALID;
				break lexmain;
			}
			break;
		}

//		debugPrint(t);

		return t;
	}

	private static void debugPrint(Token t)
	{
		switch (t.attr) {
		  case Token.NOTE:
			System.out.print((char)t.name);
			if (t.accidental > 0) {
				for (int i = 0; i < t.accidental; i++) {
					System.out.print("+");
				}
			} else if (t.accidental < 0) {
				for (int i = 0; i < -(t.accidental); i++) {
					System.out.print("-");
				}
			}
			if (t.len_flag == 1) {
				System.out.print(t.len);
			} else if (t.len_flag == 2) {
				System.out.print("%" + t.len);
			}
			for (int i = 0; i < t.dot; i++) {
				System.out.print(".");
			}
			break;
		  case Token.COMMAND0:
			System.out.print((char)t.name);
			if (t.name2 >= 0) {
				System.out.print((char)t.name2);
			}
			break;
		  case Token.COMMAND1:
			System.out.print((char)t.name);
			if (t.name2 >= 0) {
				System.out.print((char)t.name2);
			}
			System.out.print(t.param);
			break;
		  case Token.COMMAND2:
			System.out.print((char)t.name);
			if (t.name2 >= 0) {
				System.out.print((char)t.name2);
			}
			System.out.print(t.param + "," + t.param2);
			break;
		  default:
			break;
		}
		System.out.print("\n");
	}
}
