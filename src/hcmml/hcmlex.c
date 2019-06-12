/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    lexical analyzer                                                */

// #include <ctype.h>
#ifdef DEBUG
#include <stdio.h>
#endif
#include <stdlib.h>
// #include <string.h>
#include "hcmml.h"


#define ToUpper(c) (((c) >= 'a' && (c) <= 'z') ? (c) - 'a' + 'A' : (c))
#define IsDigit(c) ((c) >= '0' && (c) <= '9')

int Lex(struct Token *token, struct Line *line);
unsigned char LexGetChar(unsigned char **ptr);
void LexUngetChar(unsigned char **ptr);
long LexGetNum(unsigned char **ptr);
static void LexDebugPrint(struct Token *token);


/* Lexical analyzer */
int Lex(struct Token *token, struct Line *line) {
	int c;					/* いま読んでいる文字 */
	int attr = EOL;			/* いま読んでいる単語の属性 */
	long n;					/* 読んだ数値 */
	unsigned char *p;		/* 読み取りポインタ */

	token->u.note.accidental = 0;
	token->u.note.len = 0;
	token->u.note.dot = 0;
	token->u.note.len_flag = 0;
	p = line->pos;

	c = LexGetChar(&p);
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
		token->u.note.name = c;
		c = LexGetChar(&p);
		while (c == '#' || c == '+' || c == '-') {
			switch (c) {
			  case '#':
			  case '+':
				token->u.note.accidental++;
				break;
			  case '-':
				token->u.note.accidental--;
				break;
			}
			c = LexGetChar(&p);
		}
		if (IsDigit(c)) {
			token->u.note.len_flag = 1;
			LexUngetChar(&p);
			token->u.note.len = LexGetNum(&p);
			c = LexGetChar(&p);
		} else if (c == '%') {
			n = LexGetNum(&p);
			if (n != GETNUMFAILED) {
				token->u.note.len_flag = 2;
				token->u.note.len = n;
				c = LexGetChar(&p);
			} else {
				goto INVALID_DETECTED;
			}
		}
		while (c == '.') {
			token->u.note.dot++;
			c = LexGetChar(&p);
		}
		LexUngetChar(&p);
		attr = NOTE;
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
		token->u.command.name = c;
		attr = COMMAND0;
		break;
	  case 'O':
	  case 'T':
	  case 'Q':
	  case 'K':
		token->u.command.name = c;
		n = LexGetNum(&p);
		if (n != GETNUMFAILED) {
			token->u.command.param = n;
		} else {
			goto INVALID_DETECTED;
		}
		attr = COMMAND1;
		break;
	  case 'V':
	  case 'P':
	  case '\\':
	  case 'S':
		token->u.command.name = c;
		if ((c = LexGetChar(&p)) == '~') {
			token->u.command.name2 = c;
		} else {
			LexUngetChar(&p);
		}
		n = LexGetNum(&p);
		if (n != GETNUMFAILED) {
			token->u.command.param = n;
		} else {
			goto INVALID_DETECTED;
		}
		attr = COMMAND1;
		break;
	  case '@':
		token->u.command.name = c;
		c = LexGetChar(&p);
		if (c == 'S') {
			token->u.command.name2 = c;
			if ((n = LexGetNum(&p)) != GETNUMFAILED) {
				token->u.command.param = n;
			} else {
				goto INVALID_DETECTED;
			}
			if (LexGetChar(&p) == ','
				&& (n = LexGetNum(&p)) != GETNUMFAILED) {
				token->u.command.param2 = n;
			} else {
				goto INVALID_DETECTED;
			}
			attr = COMMAND2;
		} else {
			switch (c) {
			  case 'N':
			  case 'A':
			  case 'P':
				token->u.command.name2 = c;
				break;
			  default:
				LexUngetChar(&p);
				break;
			}
			if ((n = LexGetNum(&p)) != GETNUMFAILED) {
				token->u.command.param = n;
			} else {
				goto INVALID_DETECTED;
			}
			attr = COMMAND1;
		}
		break;
	  case '&':
		attr = SLUR;
		break;
	  case '_':
		attr = PORTAMENTO;
		break;
	  case '[':
		if ((n = LexGetNum(&p)) != GETNUMFAILED) {
			token->u.command.param = n;
		} else {
			token->u.command.param = 2;
			LexUngetChar(&p);
		}
		attr = LOOP_TOP;
		break;
	  case ']':
		attr = LOOP_BOTTOM;
		break;
	  case '/':
		attr = LOOP_EXIT;
		break;
	  case '\"':
		attr = QUOTE;
		break;
	  default:
		if (c == ';' || c == '\0') {
			attr = EOL;
		} else {
			goto INVALID_DETECTED;
		}
		break;
	}

	line->pos = p;
	token->attr = attr;
#ifdef DEBUG
	LexDebugPrint(token);
#endif
	return (attr);		/* 切り出した単語の属性を返す */

  INVALID_DETECTED:
	line->pos = p;
	token->attr = INVALID;
	return (INVALID);
}


/* 1文字取得(スペース/タブ/改行はスキップ) */
unsigned char LexGetChar(unsigned char **ptr) {
	unsigned char *p = *ptr;

	while (*p == ' ' || *p == '\t' || *p == '\n') {
		p++;
	}

	*ptr = p + 1;
	return ToUpper(*p);
}

/* 1文字戻す */
void LexUngetChar(unsigned char **ptr) {
	(*ptr)--;
}

/* 数値取得(スペース/タブ/改行はスキップ) */
long LexGetNum(unsigned char **ptr) {
	unsigned char *p = *ptr;
	long n = 0L;
	int sign = 1;

	while (*p == ' ' || *p == '\t' || *p == '\n') {
		p++;
	}
	if (*p == '-') {
		sign = -1;
		p++;
	}

	if (!IsDigit(*p)) return GETNUMFAILED;	/* この場合*ptrは更新しない */
	while (IsDigit(*p)) {
		n = n * 10 + (*p - '0');
		p++;
	}

	*ptr = p;
	return ((sign > 0) ? n : -n);
}

#ifdef DEBUG
void LexDebugPrint(struct Token *token) {
	int i;

	switch (token->attr) {
	  case NOTE:
		printf("%c", (char)token->u.note.name);
		if (token->u.note.accidental > 0) {
			for (i = 0; i < token->u.note.accidental; i++) {
				printf("+");
			}
		} else if (token->u.note.accidental < 0) {
			for (i = 0; i < -(token->u.note.accidental); i++) {
				printf("-");
			}
		}
		if (token->u.note.len_flag == 1) {
			printf("%d", token->u.note.len);
		} else if (token->u.note.len_flag == 2) {
			printf("%%%d", token->u.note.len);
		}
		for (i = 0; i < token->u.note.dot; i++) {
			printf(".");
		}
		break;
	  case COMMAND0:
		printf("%c", (char)token->u.command.name);
		if (token->u.command.name2) {
			printf("%c", (char)token->u.command.name2);
		}
		break;
	  case COMMAND1:
		printf("%c", (char)token->u.command.name);
		if (token->u.command.name2) {
			printf("%c", (char)token->u.command.name2);
		}
		printf("%d", token->u.command.param);
		break;
	  case COMMAND2:
		printf("%c", (char)token->u.command.name);
		if (token->u.command.name2) {
			printf("%c", (char)token->u.command.name2);
		}
		printf("%d,%d", token->u.command.param, token->u.command.param2);
		break;
	  default:
		break;
	}
	printf("\n");
}
#endif
