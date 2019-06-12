/* Sound Driver 'Humming Cat' for WonderWitch                         */
/*                Copyright (c) 2002-2003,2009,2019  molety           */
/*    hcmmlj - resource pack                                          */

package hcm;
import java.io.*;
import java.util.*;

public class Pack
{
	LinkedList waveFormList;
	LinkedList ampEnvList;
	LinkedList pchEnvList;
	LinkedList scoreList;

	private static final int magic = 0x5246;		// 'FR'
	private static final int resourceType = 0x4348;	// 'HC'
	private int paragraphSize;
	private int resourceID;							// リソースID
	private int packVer;							// パックバージョン
	private int compilerVer;						// コンパイラバージョン
	private int intrptFreq;							// 割り込み周波数
	private static final int reserve0 = 0;
	private int waveFormChunkOffset;
	private int ampEnvChunkOffset;
	private int pchEnvChunkOffset;
	private int scoreChunkOffset;
	private int envInterval;						// エンベロープ間隔
	private static final int reserve1 = 0;
	private int spkScaling;							// スピーカスケーリング
	private static final int reserve2 = 0;
	private Comment comment;

	private static final int WAVEFORMTYPE = 0x57;	// 'W'
	private static final int AMPENVTYPE = 0x41;		// 'A'
	private static final int PCHENVTYPE = 0x50;		// 'P'
	private static final int SCORETYPE = 0x53;		// 'S'

	public Pack()
	{
		waveFormList = new LinkedList();
		ampEnvList = new LinkedList();
		pchEnvList = new LinkedList();
		scoreList = new LinkedList();

		paragraphSize = 0;
		resourceID = 0;
		packVer = Ver.PACK_VER_ID;
		compilerVer = Ver.COMPILER_VER_ID;
		intrptFreq = 75;
		waveFormChunkOffset = 0;
		ampEnvChunkOffset = 0;
		pchEnvChunkOffset = 0;
		scoreChunkOffset = 0;
		envInterval = 1;
		spkScaling = 255;
		comment = new Comment();
	}

	public void setResourceID(int n)
	{
		resourceID = n;
	}
	public void setIntrptFreq(int n)
	{
		intrptFreq = n;
	}
	public void setEnvInterval(int n)
	{
		envInterval = n;
	}
	public void setSpkScaling(int n)
	{
		spkScaling = n;
	}
	public void setComment(String cm)
	{
		comment.set(cm);
	}

	public void addItem(WaveForm wf)
	{
		waveFormList.addLast(wf);
	}
	public void addItem(AmpEnv ae)
	{
		ampEnvList.addLast(ae);
	}
	public void addItem(PchEnv pe)
	{
		pchEnvList.addLast(pe);
	}
	public void addItem(Score sc)
	{
		scoreList.addLast(sc);
	}

	public void readFromFile(String inFilename)
	{
	}

	public void writeToFile(String outFilename) throws IOException
	{
		int pack_header_size = ((30 + comment.getSize()) + 15) & ~15;
		int pack_size = pack_header_size;
		int chunk_size = 0;

		if ((chunk_size = getChunkSize(waveFormList)) > 0) {
			waveFormChunkOffset = pack_size / 16;
			pack_size += chunk_size;
		}
		if ((chunk_size = getChunkSize(ampEnvList)) > 0) {
			ampEnvChunkOffset = pack_size / 16;
			pack_size += chunk_size;
		}
		if ((chunk_size = getChunkSize(pchEnvList)) > 0) {
			pchEnvChunkOffset = pack_size / 16;
			pack_size += chunk_size;
		}
		if ((chunk_size = getChunkSize(scoreList)) > 0) {
			scoreChunkOffset = pack_size / 16;
			pack_size += chunk_size;
		}
		paragraphSize = pack_size / 16;

		AlignOutputStream alos = new AlignOutputStream(
			new BufferedOutputStream(new FileOutputStream(outFilename)));

		alos.writeWord(magic);
		alos.writeWord(resourceType);
		alos.writeWord(paragraphSize);
		alos.writeWord(resourceID);
		alos.writeWord(packVer);
		alos.writeWord(compilerVer);
		alos.writeWord(intrptFreq);
		alos.writeWord(reserve0);
		alos.writeWord(waveFormChunkOffset);
		alos.writeWord(ampEnvChunkOffset);
		alos.writeWord(pchEnvChunkOffset);
		alos.writeWord(scoreChunkOffset);
		alos.writeWord(envInterval);
		alos.writeWord(reserve1);
		alos.writeByte(spkScaling);
		alos.writeByte(reserve2);
		alos.write(comment.getContent());
		alos.paddingToAlign(16);

		writeChunkTo(alos, waveFormList, WAVEFORMTYPE);
		writeChunkTo(alos, ampEnvList, AMPENVTYPE);
		writeChunkTo(alos, pchEnvList, PCHENVTYPE);
		writeChunkTo(alos, scoreList, SCORETYPE);

		alos.close();
	}

	private int getChunkSize(LinkedList itemList)
	{
		int size = 0;
		Iterator iter = itemList.iterator();

		while (iter.hasNext()) {
			size += 4;
			size += (((ChunkItem)iter.next()).getSize() + 1) & ~1;
		}
		if (size > 0) {
			size += 4;
		}

		return ((size + 15) & ~15);
	}

	private void writeChunkTo(AlignOutputStream alos, LinkedList itemList,
							  int type) throws IOException
	{
		int n_items = 0;
		int header_size = 0;
		int body_size = 0;
		ChunkItem item;

		Iterator iter = itemList.iterator();
		while (iter.hasNext()) {
			n_items++;
			header_size += 4;
			body_size += (((ChunkItem)iter.next()).getSize() + 1) & ~1;
		}
		if (n_items == 0)  return;
		header_size += 4;

		alos.writeByte(type);
		alos.writeByte(n_items);
		alos.writeWord((header_size + body_size + 15) / 16);

		body_size = 0;
		iter = itemList.iterator();
		while (iter.hasNext()) {
			item = (ChunkItem)iter.next();
			alos.writeByte(item.getNumber());
			alos.writeByte((header_size + body_size) & 0x0f);
			alos.writeWord((header_size + body_size) / 16);
			body_size += (item.getSize() + 1) & ~1;
		}

		iter = itemList.iterator();
		while (iter.hasNext()) {
			((ChunkItem)iter.next()).writeTo(alos);
			alos.paddingToAlign(2);
		}
		alos.paddingToAlign(16);
	}

	public void printContents()
	{
	}
}
