/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - main                                                   */

import java.io.*;
import hcm.*;

public class hcmmlj
{
	public static void main(String[] args) throws IOException
	{
		Pack pack = null;
		String target_filename = null;
		boolean bad_command_line = false;

		final int UNSPECIFIED = 1000000;	// 使用されない値にしておく
		int resource_id = UNSPECIFIED;
		int intrpt_freq = UNSPECIFIED;
		int env_interval = UNSPECIFIED;
		int spk_scaling = UNSPECIFIED;

	  command_line_reading:
		for (int i = 0; i < args.length; i++) {
			if (args[i].charAt(0) == '-' || args[i].charAt(0) == '/') {
				if (args[i].length() < 2) {
					bad_command_line = true;
					break command_line_reading;
				}
				try {
					switch (Character.toUpperCase(args[i].charAt(1))) {
					  case 'I':
						resource_id = Integer.parseInt(args[i].substring(2));
//						System.out.println("I = " + resource_id);
						break;
					  case 'F':
						intrpt_freq = Integer.parseInt(args[i].substring(2));
//						System.out.println("F = " + intrpt_freq);
						break;
					  case 'E':
						env_interval = Integer.parseInt(args[i].substring(2));
//						System.out.println("E = " + env_interval);
						break;
					  case 'S':
						spk_scaling = Integer.parseInt(args[i].substring(2));
//						System.out.println("S = " + spk_scaling);
						break;
					  default:
						bad_command_line = true;
						break command_line_reading;
					}
				} catch (NumberFormatException e) {
					bad_command_line = true;
					break command_line_reading;
				}
			} else {
				if (target_filename == null) {
					target_filename = args[i];
				} else {
					if (pack == null) pack = new Pack();
					if (args[i].toLowerCase().endsWith(".fr")) {
						// リソースパックファイル
						pack.readFromFile(args[i]);
					} else {
						// MMLファイル
						LineNumberReader lnr =
						  new LineNumberReader(new FileReader(args[i]));
						try {
							CompileCore.compile(pack, lnr);
						} catch (InvalidMMLException e) {
							System.out.println("InvalidMML at line " + lnr.getLineNumber()
											   + ": " + e.getMessage());
						} finally {
							lnr.close();
						}
					}
				}
			}
		}

		if (bad_command_line || (target_filename == null)) {
			printUsage();
			System.exit(1);
		}
		if (pack != null) {
			if (resource_id != UNSPECIFIED) pack.setResourceID(resource_id);
			if (intrpt_freq != UNSPECIFIED) pack.setIntrptFreq(intrpt_freq);
			if (env_interval != UNSPECIFIED) pack.setEnvInterval(env_interval);
			if (spk_scaling != UNSPECIFIED) pack.setSpkScaling(spk_scaling);
			pack.writeToFile(target_filename);
		} else {
			// リスト表示モード
			pack = new Pack();
			pack.readFromFile(target_filename);
			pack.printContents();
		}
	}

	private static void printUsage()
	{
		System.out.print("hcmmlj  MML compiler for 'Humming Cat' ver");
		System.out.println(Ver.getVerString(Ver.COMPILER_VER_ID));
		System.out.println("<Usage>   java hcmmlj [options] target_file input_file");
		System.out.println("<Options> -In : resource ID");
		System.out.println("          -Fn : interrupt frequency");
		System.out.println("          -En : envelope interval");
		System.out.println("          -Sn : internal speaker scaling");
	}
}
