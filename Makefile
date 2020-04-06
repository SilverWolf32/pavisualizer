#
# Makefile for pavisualizer
# vim:set fo=tcqr:
#

MODULEIMPORT=-I${PWD}/modules/ncurses -I${PWD}/modules/pulseaudio -I${PWD}/modules/kissfft
OBJECTIMPORT=modules/kissfft/kissfft/kiss_fft.o

pavisualizer: *.swift CursesUI/*.swift
	swiftc -g -o pavisualizer *.swift CursesUI/*.swift ${MODULEIMPORT} ${OBJECTIMPORT}

kissfft:
	cd modules/kissfft/kissfft && make

clean:
	rm -f pavisualizer
	rm -rf pavisualizer.dSYM/
