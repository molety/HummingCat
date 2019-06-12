一部のソースのコンパイルには、DMC付属のライブラリから
いくつかのオブジェクトを抜き出してWonderWitch用に再構築した
ライブラリが必要になります。

◎すでにそのようなライブラリを作ってある場合
sds.lib中のlmath.objとrand.objを含むライブラリを既に
作ってある場合は、流用可能です。
Makefile.dmc中でWWitch\usr\lib\libwwdmc.libとして参照されて
いるので、つじつまが合うように適当に対処して下さい。

◎まだそのようなライブラリを作っていない場合
1. DMCをWWitch\dm以下にインストールし、WWitch\dm\lib\sds.libが
   あることを確認
2. WWitch\usr\libディレクトリを作っておく
3. libwwdmcディレクトリに移ってmakeを実行
4. libwwdmc.libができているのを確認してmake installを実行

これでWWitch\usr\lib\libwwdmc.libが作られます。
