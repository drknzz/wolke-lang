all:
	happy -gca ParWolke.y
	alex -g LexWolke.x
	ghc --make TestWolke.hs -o TestWolke

clean:
	-rm -f *.log *.aux *.hi *.o *.dvi

distclean: clean
	-rm -f DocWolke.* LexWolke.* ParWolke.* LayoutWolke.* SkelWolke.* PrintWolke.* TestWolke.* AbsWolke.* TestWolke ErrM.* SharedString.* ComposOp.* Wolke.dtd XMLWolke.* Makefile*
	

