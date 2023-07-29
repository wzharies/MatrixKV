CC=g++
CXXFLAGS=-std=c++17 -c -g -o2 -Wall -fgnu-tm
INCLUDES=-I../
SOURCES=$(wildcard *.cc)
OBJECTS=$(SOURCES:.cc=.o)

all: $(SOURCES) $(OBJECTS)

.cc.o:
	$(CC) $(CXXFLAGS) $(INCLUDES) $< -o $@

clean:
	$(RM) $(OBJECTS)

