%option noyywrap
%option yylineno

%{
#include<cstdio>
#include<cstdlib>
#include<string>
#include<algorithm>
#include"symbolTable.h"

using namespace std;

int lineCount = 1;
int errorCount = 0;

int commentBeginLine;
string commentString;

FILE *logout;
FILE *tokenout;

SymbolTable* symbolTable = new SymbolTable();

void action(string lexeme, string token) {

  fprintf(tokenout, "<%s, %s>\n", token.c_str(), lexeme.c_str());
  fprintf(logout, "Line# %d: Token <%s> Lexeme %s found\n", yylineno, token.c_str(), lexeme.c_str());

  if (token == "ID") {
    bool inserted = symbolTable->insert(lexeme, token);
    if (!inserted) {
      fprintf(logout, "\t%s already exisits in the current ScopeTable\n", lexeme.c_str());
      return;
    }
    fputs(symbolTable->printAllScope().c_str(), logout);
  }
}

void detectError(string errorCode, string lexeme) {
  errorCount++;
  fprintf(logout, "Error at line# %d: %s %s\n", yylineno, errorCode.c_str(), lexeme.c_str());
}

string capitalize(string text) {
  transform(text.begin(), text.end(), text.begin(), ::toupper);
  return text;
}

string convertEscape(char c) {
  switch(c) {
    case '\'': 
      return "\'";
    case '"':
      return "\"";
    case 'n':
      return "\n";
    case 't':
      return "\t";
    case '\\': 
      return "\\";
    case 'a':
      return "\a";
    case 'f': 
      return  "\f";
    case 'r':
      return "\r";
    case 'b': 
      return "\b";
    case 'v':
      return "\v";
    case '0': 
      return "\0";
    default:
      return "";
  }
}

%}

%x COMMENT

WHITESPACE [ \t\n\r\v]+
LETTER [a-zA-Z]
DIGIT [0-9]
KEYWORD if|else|for|while|do|break|int|char|float|double|void|return|switch|case|default|continue
NUMBER [0-9]*(\.[0-9]+)?(E[-+]?[0-9]+)|[0-9]*\.[0-9]+(E[-+]?[0-9]+)?
NEWLINE [\n]
ID {LETTER}({LETTER}|{DIGIT}|_)*
CHAR \'([^'\\\n]|\\['"nt\\abfrv])+\'
STRING \"([^"\\\n]|\\\n|\\['"nt\\abfrv])*\"
SINGLE_LINE_COMMENT \/\/([^"\\\n]|\\\n)*

TOO_MANY_DECIMAL_POINTS [0-9]*\.[0-9]*(\.[0-9]*)+(E[-+]?[0-9]+)?
ILLFORMED_NUMBER {NUMBER}+
INVALID_ID_SUFFIX_NUM_PREFIX [0-9]+{ID}
UNFINISHED_CONST_CHAR \'[^\n\']*|\'\\'
UNFINISHED_STRING \"([^"\\\n]|\\\n|\\['"nt\\abfrv])*$

%%

{NEWLINE} {lineCount++;}

{KEYWORD} {action(yytext, capitalize(yytext));}

{DIGIT}+ {action(yytext, "CONST_INT");}

{NUMBER} {action(yytext, "CONST_FLOAT");}

{TOO_MANY_DECIMAL_POINTS} {
  detectError("TOO_MANY_DECIMAL_POINTS", yytext);
}

{ILLFORMED_NUMBER} {
  detectError("ILLFORMED_NUMBER", yytext);
}

{INVALID_ID_SUFFIX_NUM_PREFIX} {
  detectError("INVALID_ID_SUFFIX_NUM_PREFIX", yytext);
}

{CHAR} {
  if (yytext[1] == '\\') {
    action(convertEscape(yytext[2]), "CONST_CHAR");
  } else if (strlen(yytext) > 3) {
    detectError("MULTICHAR_CONST_CHAR", yytext);
  } else {
    action(string(1, yytext[1]), "CONST_CHAR");
  }
}

"''" {
  detectError("EMPTY_CONST_CHAR", yytext);
}

{UNFINISHED_CONST_CHAR} {
  detectError("UNFINISHED_CONST_CHAR", yytext);
}

"/*" {
  commentBeginLine = yylineno;
  commentString = "/*";
  BEGIN(COMMENT);
}

<COMMENT>"*/" {
  fprintf(logout, "Line# %d: Token <MULTI LINE COMMENT> Lexeme %s*/ found\n", commentBeginLine, commentString.c_str());
  BEGIN(INITIAL); 
}

<COMMENT>([^*]|\n)+|. {
  for (int i = 0; yytext[i] != '\0'; i++) {
    commentString += yytext[i];
    if (yytext[i] == '\n') {
      lineCount++;
    }
  }
}

<COMMENT><<EOF>> {
  cout << yytext;
  detectError("UNFINISHED_COMMENT", commentString);
  yyterminate();
}

{SINGLE_LINE_COMMENT} {

  fprintf(logout, "Line# %d: Token <SINGLE LINE COMMENT> Lexeme %s found\n", lineCount, yytext);

  for (int i = 0; yytext[i] != '\0'; i++) {
    if (yytext[i] == '\\' && yytext[i+1] == '\n') {
      lineCount++;
    }
  }
}


"++"|"--" {action(yytext, "INCOP");}

">="|"<="|"=="|"!=" {action(yytext, "RELOP");}

"&&"|"||" {action(yytext, "LOGICOP");}

"<<"|">>" {action(yytext, "BITOP");}

"+"|"-" {action(yytext, "ADDOP");}

"*"|"/"|"%" {action(yytext, "MULOP");}

"<"|">" {action(yytext, "RELOP");}

"=" {action(yytext, "ASSIGNOP");}

"&"|"|"|"^" {action(yytext, "BITOP");}

"!" {action(yytext, "NOT");}

"(" {action(yytext, "LPAREN");}

")" {action(yytext, "RPAREN");}

"{" {action(yytext, "LCURL"); symbolTable->enterScope();}

"}" {action(yytext, "RCURL"); symbolTable->exitScope();} 

"[" {action(yytext, "LSQUARE");}

"]" {action(yytext, "RSQUARE");}

"," {action(yytext, "COMMA");}

";" {action(yytext, "SEMICOLON");}


{ID} {
  action(yytext, "ID");
}

{STRING} {
  string lexeme = "";
  bool multiLine = false;

  fprintf(logout, "Line# %d: Token ", lineCount);

  for (int i = 1; yytext[i] != '\"'; i++) {
    if (yytext[i] == '\\' && yytext[i+1] == '\n') {
      lineCount++;
      multiLine = true;
      i++;
    } else if (yytext[i] == '\\') {
      lexeme += convertEscape(yytext[++i]);
    } else {
      lexeme += yytext[i];
    }
  }

  if (multiLine) { 
    fprintf(logout, "<MULTI LINE STRING> Lexeme %s found\n", yytext);
    fprintf(tokenout, "<MULTI LINE STRING, %s>\n", lexeme.c_str());
  } else {
    fprintf(logout, "<SINGLE LINE STRING> Lexeme %s found\n", yytext);
    fprintf(tokenout, "<SINGLE LINE STRING, %s>\n", lexeme.c_str());
  }
}

{UNFINISHED_STRING} {
  detectError("UNFINISHED_STRING", yytext);
}

[^ \r\n\t] {
  detectError("UNRECOGNIZED_CHAR", yytext);
}


%% 

int main(int argc, char** argv) {
  if (argc != 2) {
    cout << "Please provide an input file name and try again\n";
    return 0;
  }

  FILE *fin = fopen(argv[1], "r");
  if (fin == nullptr) {
    cout << "Cannot open specified file\n";
    return 0;
  }

  logout = fopen("log.txt", "w");
  tokenout = fopen("token.txt", "w");

  yyin = fin;
  yylex();

  fputs(symbolTable->printAllScope().c_str(), logout);
  fprintf(logout, "Total lines: %d\nTotal errors: %d", yylineno, errorCount);
  
  fclose(yyin);
  fclose(tokenout);
  fclose(logout);

  return 0;
  
}