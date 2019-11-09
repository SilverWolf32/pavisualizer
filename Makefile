#
# Makefile for pavisualizer
# vim:set fo=tcqr:
#

MODULEIMPORT=-I${PWD} libCursesUI.a -I${PWD}/modules/ncurses -I${PWD}/modules/pulseaudio

pavisualizer: *.swift
	swiftc -g -o pavisualizer *.swift ${MODULEIMPORT}

clean:
	rm -f pavisualizer
	rm -rf pavisualizer.dSYM/
