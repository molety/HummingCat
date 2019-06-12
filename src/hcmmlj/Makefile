.SUFFIXES: .class .java

CLASSES=hcmmlj.class \
        hcm\AlignOutputStream.class \
        hcm\AmpEnv.class \
        hcm\ChunkItem.class \
        hcm\Comment.class \
        hcm\CompileCore.class \
        hcm\InvalidMMLException.class \
        hcm\Lexer.class \
        hcm\Line.class \
        hcm\Pack.class \
        hcm\PchEnv.class \
        hcm\Score.class \
        hcm\Token.class \
        hcm\Track.class \
        hcm\Ver.class \
        hcm\WaveForm.class

.java.class:
	javac -source 1.4 -implicit:none $<

all:		hcmmlj.jar

hcmmlj.jar:	$(CLASSES)
	jar cvfe $@ hcmmlj $^

clean:
	-del *.class
	-del hcm\*.class
distclean:	clean
	-del *.jar
