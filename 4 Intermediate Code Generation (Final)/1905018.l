%option noyywrap
%option yylineno

%{
#include<iostream>
#include<stdlib.h>
#include<string.h>
#include<algorithm>
#include"classes/symbolInfo.h"
#include"classes/symbolTable.h"
#include "y.tab.hpp"

using namespace std;

extern YYSTYPE yylval;
extern SymbolTable* symbolTable;
void yyerror(string s);
int lineCount = 1;
int errorCount = 0;

int commentBeginLine;
string commentString;

extern FILE* logout;
extern FILE* errorout;


void action(string lexeme, string token) {
  fprintf(logout, "Line# %d: Token <%s> Lexeme %s found\n", yylineno, token.c_str(), lexeme.c_str());
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
NUMBER [0-9]*(\.[0-9]+)?(E[-+]?[0-9]+)|[0-9]*\.[0-9]+(E[-+]?[0-9]+)?
NEWLINE [\n]
ID ({LETTER}|[_])({LETTER}|{DIGIT}|_)*
CHAR \'([^'\\\n]|\\['"nt\\abfrv])+\'
STRING \"([^"\n]|\\\n|\\['"nt\\abfrv])*\"
SINGLE_LINE_COMMENT \/\/([^\n]|\\\n)*

TOO_MANY_DECIMAL_POINTS [0-9]*\.[0-9]*(\.[0-9]*)+(E[-+]?[0-9]+)?
ILLFORMED_NUMBER {NUMBER}+
INVALID_ID_SUFFIX_NUM_PREFIX [0-9]+{ID}
UNFINISHED_CONST_CHAR \'[^\n\']|\'\\'|'
UNFINISHED_STRING \"([^"\n]|\\\n|\\['"nt\\abfrv])*

%%

{NEWLINE} {lineCount++;}
{WHITESPACE} {}

"if" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "IF");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return IF;
}
"else" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "ELSE");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return ELSE;
}
"for" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "FOR");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return FOR;
}
"while" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "WHILE");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return WHILE;
}
"do" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "DO");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return DO;
}
"break" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "BREAK");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return BREAK;
}
"int" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "INT", "INT");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return INT;
}
"char" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "CHAR", "CHAR");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return CHAR;
}
"float" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "FLOAT", "FLOAT");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return FLOAT;
}
"double" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "DOUBLE", "DOUBLE");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return DOUBLE;
}
"void" {
    action(yytext, capitalize(yytext));
    SymbolInfo *s = new SymbolInfo(yytext, "VOID", "VOID");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s; 
    return VOID;
}
"return" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "RETURN");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return RETURN;
}
"switch" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "SWITCH");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return SWITCH;
}
"case" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "CASE");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return CASE;
}
"default" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "DEFAULT");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return DEFAULT;
}
"continue" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "CONTINUE");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return CONTINUE;
}

"println" {
    action(yytext, capitalize(yytext)); 
    SymbolInfo *s = new SymbolInfo(yytext, "PRINTLN");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return PRINTLN;
}

{DIGIT}+ {
    action(yytext, "CONST_INT");
    SymbolInfo *s = new SymbolInfo(yytext, "CONST_INT", "INT");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return CONST_INT;
}   

{NUMBER} {
    action(yytext, "CONST_FLOAT");
    SymbolInfo *s = new SymbolInfo(yytext, "CONST_FLOAT", "FLOAT");
    s->setStartLine(yylineno);
    yylval = (YYSTYPE)s;
    return CONST_FLOAT;   
}

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
    // escape characters

    action(convertEscape(yytext[2]), "CONST_CHAR");
    SymbolInfo* s = new SymbolInfo(convertEscape(yytext[2]), "CONST_CHAR", "CHAR");
    s->setStartLine(yylineno);
    return CONST_CHAR;
  } else if (strlen(yytext) > 3) {
    // multichar character

    detectError("MULTICHAR_CONST_CHAR", yytext);
  } else {
    // normal character

    action(string(1, yytext[1]), "CONST_CHAR");
    SymbolInfo* s = new SymbolInfo(string(1, yytext[1]), "CONST_CHAR", "CHAR");
    s->setStartLine(yylineno);
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


"++" {
  action(yytext, "INCOP");
  SymbolInfo* s = new SymbolInfo(yytext, "INCOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return INCOP;
}

"--" {
  action(yytext, "DECOP");
  SymbolInfo* s = new SymbolInfo(yytext, "DECOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return DECOP;
}

">="|"<="|"=="|"!=" {
  action(yytext, "RELOP");
  SymbolInfo* s = new SymbolInfo(yytext, "RELOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return RELOP;
}

"&&"|"||" {
  action(yytext, "LOGICOP");
  SymbolInfo* s = new SymbolInfo(yytext, "LOGICOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return LOGICOP;  
}

"<<"|">>" {
  action(yytext, "BITOP");
  SymbolInfo* s = new SymbolInfo(yytext, "BITOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return BITOP;
}

"+"|"-" {
  action(yytext, "ADDOP");
  SymbolInfo* s = new SymbolInfo(yytext, "ADDOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return ADDOP;
}

"*"|"/"|"%" {
  action(yytext, "MULOP");
  SymbolInfo* s = new SymbolInfo(yytext, "MULOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return MULOP;
}

"<"|">" {
  action(yytext, "RELOP");
  SymbolInfo* s = new SymbolInfo(yytext, "RELOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return RELOP;
}

"=" {
  action(yytext, "ASSIGNOP");
  SymbolInfo* s = new SymbolInfo(yytext, "ASSIGNOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return ASSIGNOP;
}

"&"|"|"|"^" {
  action(yytext, "BITOP");
  SymbolInfo* s = new SymbolInfo(yytext, "BITOP");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return BITOP;
}

"!" {
  action(yytext, "NOT");
  SymbolInfo* s = new SymbolInfo(yytext, "NOT");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return NOT;
}



"(" {
  action(yytext, "LPAREN");
  SymbolInfo* s = new SymbolInfo(yytext, "LPAREN");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return LPAREN;
}

")" {
  action(yytext, "RPAREN");
  SymbolInfo* s = new SymbolInfo(yytext, "RPAREN");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return RPAREN;
}

"{" {
  action(yytext, "LCURL");
  SymbolInfo* s = new SymbolInfo(yytext, "LCURL");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  // symbolTable->enterScope();
  return LCURL;
}

"}" {
  action(yytext, "RCURL");
  SymbolInfo* s = new SymbolInfo(yytext, "RCURL");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  // symbolTable->exitScope();
  return RCURL;
} 

"[" {
  action(yytext, "LSQUARE");
  SymbolInfo* s = new SymbolInfo(yytext, "LSQUARE");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return LSQUARE;
}

"]" {
  action(yytext, "RSQUARE");
  SymbolInfo* s = new SymbolInfo(yytext, "RSQUARE");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return RSQUARE;
}

"," {
  action(yytext, "COMMA");
  SymbolInfo* s = new SymbolInfo(yytext, "COMMA");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return COMMA;
}

";" {
  action(yytext, "SEMICOLON");
  SymbolInfo* s = new SymbolInfo(yytext, "SEMICOLON");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return SEMICOLON;
}

{ID} {
  action(yytext, "ID");
  SymbolInfo* s = new SymbolInfo(yytext, "ID");
  s->setStartLine(yylineno);
  yylval = (YYSTYPE)s;
  return ID;
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
  } else {
    fprintf(logout, "<SINGLE LINE STRING> Lexeme %s found\n", yytext);
  }
}

{UNFINISHED_STRING} {
  detectError("UNFINISHED_STRING", yytext);
}

[^ \r\n\t] {
  detectError("UNRECOGNIZED CHAR", yytext);
}

%%






