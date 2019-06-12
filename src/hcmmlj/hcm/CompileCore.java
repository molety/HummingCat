/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - compile core                                           */

package hcm;
import java.io.*;

public class CompileCore
{
	private static final int noteTable[] = {9, 11, 0, 2, 4, 5, 7};

	public static void compile(Pack pack, LineNumberReader lnr)
	  throws IOException, InvalidMMLException
	{
		String str;
		Line line;
		Score score = null;
		int n;
		int c;

		while ((str = lnr.readLine()) != null) {
			line = new Line(str);
		  line_scanning:
			while ((c = line.getChar()) != -1) {
				switch (c) {
				  case ';':
					break line_scanning;
				  case '#':
					c = line.getChar();
					switch (c) {
					  case '0':
					  case '1':
					  case '2':
					  case '3':
						if (score == null) {
							score = new Score(0);
							pack.addItem(score);
						}
						n = Character.digit((char)c, 10);
						if (score.track[n] == null) {
							score.track[n] = new Track();
						}
						parseTrack(score.track[n], line);
						break;
					  default:
						line.ungetChar();
						if (line.matchPattern("PACK")) {
							line.getChar();		// 空白文字をスキップ
							line.ungetChar();
							pack.setComment(line.getRemainder());
						} else if (line.matchPattern("SCORE")) {
							if (!line.isInt()) {
								throw new InvalidMMLException("Missing score No.");
							}
							n = line.getInt();
							if (score != null)  addTrackEnd(score);
							score = new Score(n);
							pack.addItem(score);
							line.getChar();		// 空白文字をスキップ
							line.ungetChar();
							score.setComment(line.getRemainder());
						} else {
							throw new InvalidMMLException("Invalid #command");
						}
						break;
					}
					break;
				  case '@':
					if (line.isInt()) {
						WaveForm waveform = new WaveForm(line.getInt());
						parseWaveForm(waveform, line);
						pack.addItem(waveform);
					} else {
						c = line.getChar();
						switch (c) {
						  case 'A':
							if (line.isInt()) {
								AmpEnv ampenv = new AmpEnv(line.getInt());
								parseAmpEnv(ampenv, line);
								pack.addItem(ampenv);
							}
							break;
						  case 'P':
							if (line.isInt()) {
								PchEnv pchenv = new PchEnv(line.getInt());
								parsePchEnv(pchenv, line);
								pack.addItem(pchenv);
							}
							break;
						  default:
							break;
						}
					}
					break;
				  case '$':
					break;
				  default:
					break;
				}
			}
		}
		if (score != null) addTrackEnd(score);

		return;
	}

	private static void addTrackEnd(Score score)
	{
		for (int i = 0; i < 4; i++) {
			if (score.track[i] != null) {
				score.track[i].writeByte(0xff);
			}
		}
	}

	private static void parseWaveForm(WaveForm waveForm, Line line)
	  throws InvalidMMLException
	{
		int c;

		for (int i = 0; i < 32; i++) {
			c = line.getChar();
			switch (c) {
			  case '0':
			  case '1':
			  case '2':
			  case '3':
			  case '4':
			  case '5':
			  case '6':
			  case '7':
			  case '8':
			  case '9':
				waveForm.write(c - '0');
				break;
			  case 'A':
			  case 'B':
			  case 'C':
			  case 'D':
			  case 'E':
			  case 'F':
				waveForm.write(c - 'A' + 10);
				break;
			  default:
				throw new InvalidMMLException("Invalid waveform data");
//				break;
			}
		}
	}

	private static void parseAmpEnv(AmpEnv ampEnv, Line line)
	  throws InvalidMMLException
	{
		Token token;
		boolean release_part_specified = false;

		while ((token = Lexer.lexer(line)).attr != Token.EOL) {
			int relative = (token.name2 == '~') ? 0x04 : 0x00;
			switch (token.attr) {
			  case Token.INVALID:
				throw new InvalidMMLException("Invalid MML");
//				break;
			  case Token.NOTE:
				switch (token.name) {
				  case 'W':
					if (token.len_flag == 1) {
						if (token.len < 60) {
							ampEnv.writeByte((token.len << 2) | 0x00);
						} else {
							ampEnv.writeByte(((token.len >> 8) << 2) | 0xf0);
							ampEnv.writeByte(token.len & 0xff);
						}
					} else {
						throw new InvalidMMLException("Invalid parameter(Wn)");
					}
					break;
				  default:
					throw new InvalidMMLException("Invalid command in AmpEnv");
//					break;
				}
				break;
			  case Token.COMMAND0:
				switch (token.name) {
				  case '|':
					if (!release_part_specified) {
						ampEnv.writeByte(0x00);
						ampEnv.setReleasePart();
						release_part_specified = true;
					} else {
						throw new InvalidMMLException("Part separator doubled");
					}
					break;
				  case '(':
					ampEnv.writeByte((-1 << 3) | 0x04 | 0x03);
					break;
				  case ')':
					ampEnv.writeByte((1 << 3) | 0x04 | 0x03);
					break;
				  default:
					throw new InvalidMMLException("Invalid command in AmpEnv");
//					break;
				}
				break;
			  case Token.COMMAND1:
				switch (token.name) {
				  case 'V':
					ampEnv.writeByte((token.param << 3) | relative | 0x03);
					break;
				  case 'P':
					ampEnv.writeByte((token.param << 3) | relative | 0x01);
					break;
				  default:
					throw new InvalidMMLException("Invalid command in AmpEnv");
//					break;
				}
				break;
			  case Token.LOOP_TOP:
				if (token.param < 60) {
					ampEnv.writeByte((token.param << 2) | 0x02);
				} else {
					ampEnv.writeByte(((token.param >> 8) << 2) | 0xf2);
					ampEnv.writeByte(token.param & 0xff);
				}
				break;
			  case Token.LOOP_BOTTOM:
				ampEnv.writeByte((1 << 2) | 0x02);
				break;
			  default:
				throw new InvalidMMLException("Invalid command in AmpEnv");
//				break;
			}
		}
		if (!release_part_specified) {
			ampEnv.writeByte(0x00);
			ampEnv.setReleasePart();
		}
		ampEnv.writeByte(0x00);
	}

	private static void parsePchEnv(PchEnv pchEnv, Line line)
	  throws InvalidMMLException
	{
		Token token;
		boolean release_part_specified = false;

		while ((token = Lexer.lexer(line)).attr != Token.EOL) {
			int relative = (token.name2 == '~') ? 0x04 : 0x00;
			switch (token.attr) {
			  case Token.INVALID:
				throw new InvalidMMLException("Invalid MML");
//				break;
			  case Token.NOTE:
				switch (token.name) {
				  case 'W':
					if (token.len_flag == 1) {
						if (token.len < 60) {
							pchEnv.writeByte((token.len << 2) | 0x00);
						} else {
							pchEnv.writeByte(((token.len >> 8) << 2) | 0xf0);
							pchEnv.writeByte(token.len & 0xff);
						}
					} else {
						throw new InvalidMMLException("Invalid parameter(Wn)");
					}
					break;
				  default:
					throw new InvalidMMLException("Invalid command in PchEnv");
//					break;
				}
				break;
			  case Token.COMMAND0:
				switch (token.name) {
				  case '|':
					if (!release_part_specified) {
						pchEnv.writeByte(0x00);
						pchEnv.setReleasePart();
						release_part_specified = true;
					} else {
						throw new InvalidMMLException("Part separator doubled");
					}
					break;
				  default:
					throw new InvalidMMLException("Invalid command in PchEnv");
//					break;
				}
				break;
			  case Token.COMMAND1:
				int command_flag = 0x03;
				switch (token.name) {
				  case '\\':
					command_flag = 0x03;
					break;
				  case 'S':
					command_flag = 0x01;
					break;
				  default:
					throw new InvalidMMLException("Invalid command in PchEnv");
//					break;
				}
				if (token.param >= -15 && token.param <= 15) {
					pchEnv.writeByte((token.param << 3) | relative | command_flag);
				} else {
					pchEnv.writeByte((0x10 << 3) | relative | command_flag);
					if (token.param >= -63 && token.param <= 63) {
						pchEnv.writeByte(token.param << 1);
					} else {
						pchEnv.writeByte(((token.param >> 8) << 1) | 0x01);
						pchEnv.writeByte(token.param & 0xff);
					}
				}
				break;
			  case Token.LOOP_TOP:
				if (token.param < 60) {
					pchEnv.writeByte((token.param << 2) | 0x02);
				} else {
					pchEnv.writeByte(((token.param >> 8) << 2) | 0xf2);
					pchEnv.writeByte(token.param & 0xff);
				}
				break;
			  case Token.LOOP_BOTTOM:
				pchEnv.writeByte((1 << 2) | 0x02);
				break;
			  default:
				throw new InvalidMMLException("Invalid command in PchEnv");
//				break;
			}
		}
		if (!release_part_specified) {
			pchEnv.writeByte(0x00);
			pchEnv.setReleasePart();
		}
		pchEnv.writeByte(0x00);
	}

	private static void parseTrack(Track track, Line line)
	  throws InvalidMMLException
	{
		Token token;
		boolean quoted = false;
		int abslen = -1;

		while ((token = Lexer.lexer(line)).attr != Token.EOL) {
			switch (token.attr) {
			  case Token.INVALID:
				throw new InvalidMMLException("Invalid MML");
//				break;
			  case Token.QUOTE:
				quoted = !quoted;
				break;
			  case Token.NOTE:
				switch (token.len_flag) {
				  case 0:
					if (token.dot == 0) {
						abslen = -1;		// デフォルト音長を使用
					} else {
						abslen = track.defaultLen;
						for (int i = 0; i < token.dot; i++) {
							abslen += track.defaultLen >> (i + 1);
						}
					}
					break;
				  case 1:
					if (token.len == 0) {
						throw new InvalidMMLException("Can't use length0");
					}
					abslen = 192 / token.len;
					for (int i = 0; i < token.dot; i++) {
						abslen += (192 / token.len) >> (i + 1);
					}
					break;
				  case 2:
					abslen = token.len;
					for (int i = 0; i < token.dot; i++) {
						abslen += (token.len) >> (i + 1);
					}
					break;
				}
				switch (token.name) {
				  case 'A':
				  case 'B':
				  case 'C':
				  case 'D':
				  case 'E':
				  case 'F':
				  case 'G':
					track.writeNote(noteTable[token.name - 'A']
									+ token.accidental + ((track.octave - 1) * 12), abslen);
					break;
				  case 'R':
					track.writeNote(0, abslen);
					break;
				  case 'W':
					track.writeNote(1, abslen);
					break;
				  case 'L':
					if (abslen < 0 || abslen > 255) {
						throw new InvalidMMLException("Invalid parameter(Ln)");
					}
					track.defaultLen = abslen;
					track.writeByte(0xc1);
					track.writeByte(abslen);
					break;
				}
				break;
			  case Token.COMMAND0:
				switch (token.name) {
				  case '<':
					track.octave--;
					if (track.octave < 1) throw new InvalidMMLException("Too low octave");
					break;
				  case '>':
					track.octave++;
					if (track.octave > 8) throw new InvalidMMLException("Too high octave");
					break;
				  case '(':
					track.writeByte(0xdd);
					break;
				  case ')':
					track.writeByte(0xdc);
					break;
				}
				break;
			  case Token.COMMAND1:
				switch (token.name) {
				  case 'O':
					track.octave = token.param;
					if (track.octave < 1 || track.octave > 8) {
						throw new InvalidMMLException("Invalid parameter(On)");
					}
					break;
				  case 'T':
					track.writeByte(0xc0);
					track.writeByte(token.param & 0xff);
					track.writeByte(token.param >> 8);
					break;
				  case 'Q':
					track.writeByte(0xc2 + token.param);
					break;
				  case 'V':
					if (token.name2 == '~') {
						track.writeByte(0xdb);
						track.writeByte(token.param);
					} else {
						track.writeByte(0xcb + token.param);
					}
					break;
				  case 'P':
					if (token.name2 == '~') {
						track.writeByte(0xdf);
					} else {
						track.writeByte(0xde);
					}
					track.writeByte(token.param);
					break;
				  case '\\':
					if (token.name2 == '~') {
						track.writeByte(0xe1);
					} else {
						track.writeByte(0xe0);
					}
					track.writeByte(token.param & 0xff);
					track.writeByte(token.param >> 8);
					break;
				  case 'S':
					if (token.name2 == '~') {
						track.writeByte(0xe3);
					} else {
						track.writeByte(0xe2);
					}
					track.writeByte(token.param & 0xff);
					track.writeByte(token.param >> 8);
					break;
				  case '@':
					switch (token.name2) {
					  case -1:
						track.writeByte(0xeb);
						track.writeByte(token.param);
						break;
					  case 'A':
						track.writeByte(0xec);
						track.writeByte(token.param);
						break;
					  case 'P':
						track.writeByte(0xed);
						track.writeByte(token.param);
						break;
					  case 'N':
						track.writeByte(0xea);
						track.writeByte(token.param);
						break;
					  default:
						throw new InvalidMMLException("Invalid command");
//						break;
					}
					break;
				  default:
					throw new InvalidMMLException("Invalid command");
//					break;
				}
				break;
			  case Token.COMMAND2:
				break;
			  case Token.SLUR:
				track.slurCount++;
				break;
			  case Token.PORTAMENTO:
				throw new InvalidMMLException("Not supported yet!");
//				break;
			  case Token.LOOP_TOP:
				track.writeByte(0xee);
				track.writeByte(token.param);
				break;
			  case Token.LOOP_BOTTOM:
				track.writeByte(0xef);
				break;
			  case Token.LOOP_EXIT:
				track.writeByte(0xf0);
				break;
			  default:
				throw new InvalidMMLException("Internal Error (Unknown status)");
//				break;
			}
		}
		return;
	}
}
