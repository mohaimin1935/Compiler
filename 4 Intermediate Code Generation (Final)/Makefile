main:
	bison -g -Wno-yacc -d -y -o y.tab.cpp 1905018_no_error_handling.y
	g++ -g -w -c -o y.o y.tab.cpp
	flex -o lex.yy.cpp 1905018.l
	g++ -g -fpermissive -w -c -o l.o lex.yy.cpp
	g++ -g y.o l.o -lfl -o 1905018
	./1905018 input.c

