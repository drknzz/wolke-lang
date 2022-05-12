all:
	cd src && ghc --make Main.hs -o ../interpreter

clean:
	rm -f src/Gen/*.o
	rm -f src/Gen/*.hi
	rm -f src/*.o
	rm -f src/*.hi
	rm -f interpreter