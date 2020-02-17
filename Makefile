#
# Makefile for pavisualizer
# vim:set fo=tcqr:
#

MODULEIMPORT=-I${PWD} libCursesUI.a -I${PWD}/modules/ncurses -I${PWD}/modules/pulseaudio -I${PWD}/modules/kissfft
OBJECTIMPORT=modules/kissfft/kissfft/kiss_fft.o

pavisualizer: *.swift
	swiftc -g -o pavisualizer *.swift ${MODULEIMPORT} ${OBJECTIMPORT}

clean:
	rm -f pavisualizer
	rm -rf pavisualizer.dSYM/
