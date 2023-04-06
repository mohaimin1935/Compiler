%{
#include <cmath>
#include <cstdlib>
#include <cstring>
#include <iostream>

#include "symbolInfo.h"
#include "symbolTable.h"

#define YYSTYPE SymbolInfo*

    using namespace std;

    extern FILE* yyin;
    SymbolTable* symbolTable = new SymbolTable();
    SymbolInfo* argumentInfo = new SymbolInfo();
    extern int yylineno;
    extern int errorCount;

    FILE* fp;
    FILE* logout;
    FILE* errorout;
    FILE* parseTreeOut;

    void yyerror(string s) {
        errorCount++;
        fprintf(errorout, "Line# %d: %s\n", yylineno, s.c_str());
    }

    void logOutput(string parent, string child) {
        fprintf(logout, "%s : %s\n", parent.c_str(), child.c_str());
    }

    string errorSymbol(SymbolInfo * info) {
        return ("'" + info->getName() + "'");
    }

    void insertToSymbolTable(SymbolInfo * symbolInfo, string errorText = "Conflicting types for ") {
        // handle void variable
        if (symbolInfo->getTypeSpecifier() == "VOID") {
        	yyerror("Variable or field " + errorSymbol(symbolInfo) +" declared void");
            return;
        }

        bool inserted = symbolTable->insert(symbolInfo);
        if (!inserted) {
            yyerror(errorText + errorSymbol(symbolInfo));
        }
    }

    void insertFunctionDeclaration(SymbolInfo * functionDeclaration) {
        bool inserted = symbolTable->insert(functionDeclaration);

        if (!inserted) {
            yyerror("Multiple declaration of " + errorSymbol(functionDeclaration));
        }
    }

    void insertFunction(SymbolInfo * function, SymbolInfo * returnType, SymbolInfo * parameters) {
        function->setType("FUNCTION");
        function->setReturnType(returnType->getName());
        function->setTypeSpecifier(returnType->getName());
        function->setParameters(parameters->getParameters());
        function->setFunctionDefinition(true);

        bool inserted = symbolTable->insert(function);
        if (inserted) {
            return;
        }

        SymbolInfo* prevFunction = symbolTable->lookup(function->getName());

        if (!prevFunction->isFunctionDeclaration()) {
            // prev is not a function declaration: error
            if (!(prevFunction->isFunctionDeclaration())) {
                yyerror(errorSymbol(function) + " redeclared as different kind of symbol");
            }
        } else {
            // prev is a function declaration
            if (prevFunction->getReturnType() != function->getReturnType()) {
                // return type mismatch
                yyerror("Conflicting return types for " + errorSymbol(function));
            } else if (prevFunction->getParameters().size() != function->getParameters().size()) {
                // no of arguments mismatch
                yyerror("Conflicting types for " + errorSymbol(function));
            } else {
                // match the arguments of prev and function
                // report error if mismatch
                auto argumentsDeclaration = prevFunction->getParameters();
                auto argumentsDefinition = function->getParameters();

                for (int i = 0; i < argumentsDeclaration.size(); i++) {
                    if (argumentsDeclaration[i]->getTypeSpecifier() != argumentsDefinition[i]->getTypeSpecifier()) {
                        yyerror("Type mismatch for argument " + to_string(i + 1) + " of " + errorSymbol(function));
                        return;
                    }
                }
            }
        }
    }

    string typeCast(SymbolInfo * left, SymbolInfo * right) {
        string leftType = left->getTypeSpecifier();
        string rightType = right->getTypeSpecifier();
        // if (leftType == "INT" && rightType == "FLOAT") {
        //     yyerror("Warning: possible loss of data in assignment of FLOAT to INT");
        // }
        if (leftType == "error" || rightType == "error") {
            return "error";
        }
        if (leftType == "FLOAT" or rightType == "FLOAT") {
            return "FLOAT";
        }

        return "INT";
    }

    void buildParseTree(SymbolInfo* left, vector<SymbolInfo*> rights) {
        left->setChildren(rights);
        left->setStartLine(rights[0]->getStartLine());
    }

    void preOrderParaseTree(SymbolInfo* head) {
        fprintf(parseTreeOut, head->printNode().c_str());
        for (auto child: head->getChildren()) {
            child->setDepth(head->getDepth() + 1);
            preOrderParaseTree(child);
        }
    }

    int yyparse(void);
    int yylex(void);

%}

%define parse.error verbose 
%define api.value.type{SymbolInfo *}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE CONST_INT CONST_FLOAT CONST_CHAR INCOP LOGICOP ADDOP MULOP RELOP ASSIGNOP BITOP NOT LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE COMMA SEMICOLON ID PRINTLN DECOP THEN

%type start program unit func_declaration func_definition parameter_list compound_statement var_declaration type_specifier declaration_list statements statement expression_statement variable expression logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments lcurl

%right ELSE THEN  // same precedence but shift wins


%%

    start : program {
        logOutput("start", "program");
        $$ = new SymbolInfo("", "start");
        $$->setDepth(0);
        buildParseTree($$, {$1});

        preOrderParaseTree($$);
    };

    program : program unit {
        logOutput("program", "program unit");
        $$ = new SymbolInfo("", "program");
        buildParseTree($$, {$1, $2});
    }
    | unit {
        logOutput("program", "unit");
        $$ = new SymbolInfo("", "program");
        buildParseTree($$, {$1});
    };

    unit : var_declaration {
        logOutput("unit", "var_declaration");
        $$ = new SymbolInfo("", "unit");
        buildParseTree($$, {$1});
    }
    | func_declaration {
        logOutput("unit", "func_declaration");
        $$ = new SymbolInfo("", "unit");
        buildParseTree($$, {$1});
    }
    | func_definition {
        logOutput("unit", "func_definition");
        $$ = new SymbolInfo("", "unit");
        buildParseTree($$, {$1});
    };

    func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
        logOutput("func_declaration", "type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
        $$ = new SymbolInfo("", "func_declaration");
        buildParseTree($$, {$1, $2, $3, $4, $5, $6});

        // $2 is the function id
        $2->setFunctionDeclaration(true);
        $2->setType("FUNCTION");
        $2->setReturnType($1->getName());
        $2->setTypeSpecifier($1->getName());
        $2->setParameters($4->getParameters());

        argumentInfo->setParameters({});
        insertFunctionDeclaration($2);
    }
    | type_specifier ID LPAREN RPAREN SEMICOLON {
        logOutput("func_declaration", "type_specifier ID LPAREN RPAREN SEMICOLON");
        $$ = new SymbolInfo("", "func_declaration");
        buildParseTree($$, {$1, $2, $3, $4, $5});
        $2->setFunctionDeclaration(true);
        $2->setType("FUNCTION");
        $2->setReturnType($1->getName());
        $2->setTypeSpecifier($1->getName());
        argumentInfo->setParameters({});
        insertFunctionDeclaration($2);
    };

    func_definition : type_specifier ID LPAREN parameter_list RPAREN {
        insertFunction($2, $1, $4);
    } compound_statement {
        logOutput("func_definition", "type_specifier ID LPAREN parameter_list RPAREN compound_statement");
        $$ = new SymbolInfo("", "func_definition");
        buildParseTree($$, {$1, $2, $3, $4, $5, $7});
        // no need to update $2, it is handled in insertFunction
    }
    | type_specifier ID LPAREN RPAREN {
        insertFunction($2, $1, new SymbolInfo("", ""));
    } compound_statement {
        $$ = new SymbolInfo("", "func_definition");
        buildParseTree($$, {$1, $2, $3, $4, $6});
        logOutput("func_definition", "type_specifier ID LPAREN RPAREN compound_statement");
    };

    parameter_list : parameter_list COMMA type_specifier ID {
        logOutput("parameter_list", "parameter_list COMMA type_specifier ID");
        $$ = new SymbolInfo("", "parameter_list");
        buildParseTree($$, {$1, $2, $3, $4});
        $$->setParameters($1->getParameters());
        $4->setType($3->getName());
        $4->setTypeSpecifier($3->getName());
        $$->pushParameter($4);
        argumentInfo->setParameters($$->getParameters());
    }
    | parameter_list COMMA type_specifier {
        logOutput("parameter_list", "parameter_list COMMA type_specifier");
        $$ = new SymbolInfo("", "parameter_list");
        buildParseTree($$, {$1, $2, $3});
        $$->setParameters($1->getParameters());
        $$->pushParameter(new SymbolInfo("", $3->getName(), $3->getName(), $3->getName()));
        argumentInfo->setParameters($$->getParameters());
    }
    | type_specifier ID {
        logOutput("parameter_list", "type_specifier ID");
        $$ = new SymbolInfo("", "parameter_list");
        buildParseTree($$, {$1, $2});
        $2->setType($1->getName());
        $2->setTypeSpecifier($1->getName());
        $$->pushParameter($2);
        argumentInfo->setParameters($$->getParameters());
    }
    | type_specifier {
        logOutput("parameter_list", "type_specifier");
        $$ = new SymbolInfo("", "parameter_list");
        buildParseTree($$, {$1});
        $$->pushParameter(new SymbolInfo("", $1->getName(), $1->getName(), $1->getName()));
        argumentInfo->setParameters($$->getParameters());
    };

    compound_statement : lcurl statements RCURL {
        logOutput("compound_statement", "LCURL statements RCURL");
        $$ = new SymbolInfo("", "compound_statement");
        buildParseTree($$, {$1, $2, $3});
        fputs(symbolTable->printAllScope().c_str(), logout);
        symbolTable->exitScope();
    }
    | lcurl RCURL {};

    var_declaration : type_specifier declaration_list SEMICOLON {
        logOutput("var_declaration", "type_specifier declaration_list SEMICOLON");
        $$ = new SymbolInfo("", "var_declaration");
        buildParseTree($$, {$1, $2, $3});

        for (auto symbolInfo : $2->getDeclarations()) {
            symbolInfo->setType($1->getName());
            insertToSymbolTable(symbolInfo);
        }
    };

    type_specifier : INT {
        logOutput("type_specifier", "INT");
        $$ = new SymbolInfo("INT", "type_specifier", "INT");
        buildParseTree($$, {$1});
    }
    | FLOAT {
        logOutput("type_specifier", "FLOAT");
        $$ = new SymbolInfo("FLOAT", "type_specifier", "FLOAT");
        buildParseTree($$, {$1});
    }
    | VOID {
        logOutput("type_specifier", "VOID");
        $$ = new SymbolInfo("VOID", "type_specifier", "DOUBLE");
        buildParseTree($$, {$1});
    };

    declaration_list : declaration_list COMMA ID {
        // a, b, | c
        logOutput("declaration_list", "declaration_list COMMA ID");
        $$ = new SymbolInfo("", "declaration_list");
        buildParseTree($$, {$1, $2, $3});
        $$->setDeclarations($1->getDeclarations());
        $$->pushDeclaration($3);
    }
    | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
        // a, b, | c[8]
        logOutput("declaration_list", "declaration_list COMMA ID LSQUARE CONST_INT RSQUARE");
        $$ = new SymbolInfo("", "declaration_list");
        buildParseTree($$, {$1, $2, $3, $4, $5, $6});
        $$->setDeclarations($1->getDeclarations());
        $3->setArray(true);
        $$->pushDeclaration($3);
    }
    | ID {
        logOutput("declaration_list", "ID");
        $$ = new SymbolInfo("", "declaration_list");
        buildParseTree($$, {$1});
        $$->pushDeclaration($1);
    }
    | ID LSQUARE CONST_INT RSQUARE {
        logOutput("declaration_list", "ID LSQUARE CONST_INT RSQUARE");
        $$ = new SymbolInfo("", "declaration_list");
        buildParseTree($$, {$1, $2, $3, $4});
        $1->setArray(true);
        $$->pushDeclaration($1);
    };

    statements : statement {
        logOutput("statements", "statement");
        $$ = new SymbolInfo("", "statements");
        buildParseTree($$, {$1});
    }
    | statements statement {
        logOutput("statements", "statements statement");
        $$ = new SymbolInfo("", "statements");
        buildParseTree($$, {$1, $2});
    };

    statement : var_declaration {
        logOutput("statement", "var_declaration");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1});
    }
    | expression_statement {
        logOutput("statement", "expression_statement");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1});
    }
    | compound_statement {
        logOutput("statement", "compound_statement");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1});
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
        logOutput("statement", "FOR LPAREN expression_statement expression_statement expression RPAREN statement");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1, $2, $3, $4, $5, $6, $7});
    }
    | IF LPAREN expression RPAREN statement {
        logOutput("statement", "IFLPAREN expression RPAREN statement");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1, $2, $3, $4, $5});
    } %prec THEN  // less precedence
    | IF LPAREN expression RPAREN statement ELSE statement {
        logOutput("statement", "IF LPAREN expression RPAREN statement ELSE statement");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1, $2, $3, $4, $5, $6, $7});
    }
    | WHILE LPAREN expression RPAREN statement {
        logOutput("statement", "WHILE LPAREN expression RPAREN statement");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1, $2, $3, $4, $5});
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON {
        // FIXME: never enter this grammar
        logOutput("statement", "PRINTLN LPAREN ID RPAREN SEMICOLON");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1, $2, $3, $4, $5});

        if (!symbolTable->lookup($3->getName())) {
            yyerror("Undeclared variable " + errorSymbol($3));
        }
    }
    | RETURN expression SEMICOLON {
        logOutput("statement", "RETURN expression SEMICOLON");
        $$ = new SymbolInfo("", "statement");
        buildParseTree($$, {$1, $2, $3});
    };

    expression_statement : SEMICOLON {
        logOutput("expression_statement", "SEMICOLON");
        $$ = new SymbolInfo("", "expression_statement");
        buildParseTree($$, {$1});
    }
    | expression SEMICOLON {
        logOutput("expression_statement", "expression SEMICOLON");
        $$ = new SymbolInfo("", "expression_statement");
        $$->setTypeSpecifier($1->getTypeSpecifier());
        buildParseTree($$, {$1, $2});
    };

    variable : ID { 
        logOutput("variable", "ID");
        $$ = new SymbolInfo("", "variable");
        buildParseTree($$, {$1});

        SymbolInfo* search = symbolTable->lookup($1->getName());

        if (search == nullptr) {
            yyerror("Undeclared variable " + errorSymbol($1));
            $$->setTypeSpecifier("error");
        } else if (search->isArray()) {
            $$->setTypeSpecifier(search->getTypeSpecifier());
            $$->setArray(search->isArray());
        } else {
            $$->setTypeSpecifier(search->getTypeSpecifier());
            $$->setArray(search->isArray());
        }
    }
    | ID LSQUARE expression RSQUARE {
        logOutput("variable", "ID LSQUARE expression RSQUARE");
        $$ = new SymbolInfo("", "variable");
        buildParseTree($$, {$1, $2, $3, $4});

        SymbolInfo* search = symbolTable->lookup($1->getName());

        if (search == nullptr) {
            yyerror("Undeclared variable " + errorSymbol($1));
        } else if (!search->isArray()) {
            yyerror(errorSymbol($1) + " is not an array");
            $$->setTypeSpecifier(search->getTypeSpecifier());
        } else {
            $$->setTypeSpecifier(search->getTypeSpecifier());
        }
        if ($3->getTypeSpecifier() != "INT") {
            yyerror("Array subscript is not an integer");
        }
    };
    // TODO: upto this typespecifier of expression done
    expression : logic_expression {
        logOutput("expression", "logic_expression");
        $$ = new SymbolInfo("", "expression", $1->getTypeSpecifier());
        buildParseTree($$, {$1});
        $$->setTypeSpecifier($1->getTypeSpecifier());
    }
    | variable ASSIGNOP logic_expression {
        logOutput("expression", "variable ASSIGNOP logic_expression");
        $$ = new SymbolInfo("", "expression");
        buildParseTree($$, {$1, $2, $3});
        $$->setTypeSpecifier($1->getTypeSpecifier());

        if ($1->getTypeSpecifier() == "INT" && $3->getTypeSpecifier() == "FLOAT") {
            yyerror("Warning: possible loss of data in assignment of FLOAT to INT");
        }

        if ($3->getTypeSpecifier() == "VOID") {
            yyerror("Void function cannot be used in expression");
        } else if ($1->getTypeSpecifier() == "FLOAT" && $3->getTypeSpecifier() == "INT") {
            // auto cast
        } else if ($1->getTypeSpecifier() != $3->getTypeSpecifier() && $1->getTypeSpecifier() != "error" && $3->getTypeSpecifier() == "error") {
            // FIXME: 
            // yyerror("Type mismatch");
        }
    };

    logic_expression : rel_expression {
        logOutput("logic_expression", "rel_expression");
        $$ = new SymbolInfo("", "logic_expression");
        buildParseTree($$, {$1});
        $$->setArray($1->isArray());
        $$->setTypeSpecifier($1->getTypeSpecifier());
    }
    | rel_expression LOGICOP rel_expression {
        logOutput("logic_expression", "rel_expression LOGICOP rel_expression");
        $$ = new SymbolInfo("", "logic_expression");
        buildParseTree($$, {$1, $2, $3});
        $$->setTypeSpecifier("INT");
    };

    rel_expression : simple_expression {
        logOutput("rel_expression", "simple_expression");
        $$ = new SymbolInfo("", "rel_expression");
        buildParseTree($$, {$1});
        $$->setTypeSpecifier($1->getTypeSpecifier());
        $$->setArray($1->isArray());
    }
    | simple_expression RELOP simple_expression {
        logOutput("rel_expression", "simple_expression RELOP simple_expression");
        $$ = new SymbolInfo("", "rel_expression");
        buildParseTree($$, {$1, $2, $3});
        if ($1->getTypeSpecifier() == "VOID" or $3->getTypeSpecifier() == "VOID") {
            yyerror("Void cannot be used in expression");
            $$->setTypeSpecifier("error");
        } else {
            $$->setTypeSpecifier("INT");
        }
    };

    simple_expression : term {
        logOutput("simple_expression", "term");
        $$ = new SymbolInfo("", "simple_expression");
        buildParseTree($$, {$1});
        $$->setTypeSpecifier($1->getTypeSpecifier());
        $$->setArray($1->isArray());
    }
    | simple_expression ADDOP term {
        logOutput("simple_expression", "simple_expression ADDOP term");
        $$ = new SymbolInfo("", "simple_expression");
        buildParseTree($$, {$1, $2, $3});
        $$->setTypeSpecifier(typeCast($1, $3));
        if ($3->getTypeSpecifier() == "VOID") {
            yyerror("Void cannot be used in expression");
        }
    };

    term : unary_expression {
        logOutput("term", "unary_expression");
        $$ = new SymbolInfo("", "term");
        buildParseTree($$, {$1});
        $$->setTypeSpecifier($1->getTypeSpecifier());
        $$->setArray($1->isArray());
    }
    | term MULOP unary_expression {
        logOutput("term", "term MULOP unary_expression");
        $$ = new SymbolInfo("", "term");
        buildParseTree($$, {$1, $2, $3});
        $$->setTypeSpecifier(typeCast($1, $3));

        if ($3->getTypeSpecifier() == "VOID") {
            yyerror("Void cannot be used in expression");
        } else if ($2->getName() == "%" and $3->getName() == "0") {
            yyerror("Warning: division by zero");
            $$->setTypeSpecifier("error");
        }
        else if($2->getName() == "%" && ( $1->getTypeSpecifier() != "INT" || $3->getTypeSpecifier() != "INT") ){
        	yyerror("Operands of modulus must be integers ");
        	$$->setTypeSpecifier("error");
        }
    };

    unary_expression : ADDOP unary_expression {
        logOutput("unary_expression", "ADDOP unary_expression");
        $$ = new SymbolInfo("", "unary_expression");
        buildParseTree($$, {$1, $2});
        if ($2->getTypeSpecifier() == "VOID" ){
			yyerror("Void cannot be used in expression");
			$$->setTypeSpecifier("error");
		} else{
			$$->setTypeSpecifier($2->getTypeSpecifier());
		}
    }
    | NOT unary_expression {
        logOutput("unary_expression", "NOT unary_expression");
        $$ = new SymbolInfo("", "unary_expression");
        buildParseTree($$, {$1, $2});

        if ($2->getTypeSpecifier() == "VOID") {
            yyerror("Void cannot be used in expression");
            $$->setTypeSpecifier("error");
        } else {
            $$->setTypeSpecifier("INT");
        }
    }
    | factor {
        logOutput("unary_expression", "factor");
        $$ = new SymbolInfo($1->getName(), "unary_expression");
        buildParseTree($$, {$1});
        $$->setTypeSpecifier($1->getTypeSpecifier());
        $$->setArray($1->isArray());
    };

    factor : variable {
        logOutput("factor", "variable");
        $$ = new SymbolInfo("", "factor");
        buildParseTree($$, {$1});
        $$->setTypeSpecifier($1->getTypeSpecifier());
        $$->setArray($1->isArray());
    }
    | ID LPAREN argument_list RPAREN {
        // function call
        // FIXME: ID LPAREN RPAREN : void function call
        logOutput("factor", "ID LPAREN argument_list RPAREN");
        $$ = new SymbolInfo("", "factor");
        buildParseTree($$, {$1, $2, $3, $4});

        SymbolInfo* search = symbolTable->lookup($1->getName());
        
        if (search == nullptr) {
            yyerror("Undeclared function " + errorSymbol($1));
        } else {
            auto argumentsDeclaration = search->getParameters();
            auto argumentsCall = $3->getParameters();

            $$->setTypeSpecifier(search->getTypeSpecifier());
            if (!search->isFunctionDeclaration() && !search->isFunctionDefinition()) {
                yyerror(errorSymbol($1) + " is not a function");
            } else if (argumentsDeclaration.size() > argumentsCall.size()) {
                yyerror("Too few arguments to function " + errorSymbol($1));
            } else if (argumentsDeclaration.size() < argumentsCall.size()) {
                yyerror("Too many arguments to function " + errorSymbol($1));
            } else {

                for (int i = 0; i < argumentsDeclaration.size(); i++) {
                    if (argumentsDeclaration[i]->getTypeSpecifier() != argumentsCall[i]->getTypeSpecifier()) {
                        yyerror("Type mismatch for argument " + to_string(i + 1) + " of " + errorSymbol(search));
                    }
                    if (argumentsDeclaration[i]->isArray() != argumentsCall[i]->isArray()) {
                        yyerror("Type mismatch (array) for argument" + to_string(i + 1) + " of " + errorSymbol(search));
                    }
                }
            }
        }
    }
    | LPAREN expression RPAREN {
        logOutput("factor", "LPAREN expression RPAREN");
        $$ = new SymbolInfo("", "factor");
        buildParseTree($$, {$1, $2, $3});
        $$->setTypeSpecifier($2->getTypeSpecifier());
    }
    | CONST_INT {
        logOutput("factor", "CONST_INT");
        $$ = new SymbolInfo($1->getName(), "factor");
        buildParseTree($$, {$1});
        $$->setTypeSpecifier("INT");
    }
    | CONST_FLOAT {
        logOutput("factor", "CONST_FLOAT");
        $$ = new SymbolInfo($1->getName(), "factor");
        buildParseTree($$, {$1});
        $$->setTypeSpecifier("FLOAT");
    }
    | variable INCOP {
        logOutput("factor", "INCOP");
        $$ = new SymbolInfo("", "factor");
        buildParseTree($$, {$1, $2});
        if ($1->getTypeSpecifier() == "VOID") {
            yyerror("Void function is used in expression");
            $$->setTypeSpecifier("error");
        } else {
            $$->setTypeSpecifier($1->getTypeSpecifier());
        }
    }
    | variable DECOP {
        logOutput("factor", "DECOP");
        $$ = new SymbolInfo("", "factor");
        buildParseTree($$, {$1, $2});
        if ($1->getTypeSpecifier() == "VOID") {
            yyerror("Void function is used in expression");
            $$->setTypeSpecifier("error");
        } else {
            $$->setTypeSpecifier($1->getTypeSpecifier());
        }
    };

    argument_list : arguments {
        logOutput("argument_list", "arguments");
        $$ = new SymbolInfo("", "argument_list");
        buildParseTree($$, {$1});
        $$->setParameters($1->getParameters());
    }
    | { /*for void function call*/ };

    arguments : arguments COMMA logic_expression {
        logOutput("arguments", "arguments COMMA logic_expression");
        $$ = new SymbolInfo("", "arguments");
        buildParseTree($$, {$1, $2, $3});
        $$->setParameters($1->getParameters());
        $$->pushParameter($3);
    }
    | logic_expression {
        logOutput("arguments", "logic_expression");
        $$ = new SymbolInfo("", "arguments");
        buildParseTree($$, {$1});
        $$->pushParameter($1);
    };

    lcurl : LCURL {
        symbolTable->enterScope();
        $$ = $1;
        // insert arguments with names
        for (auto argument: argumentInfo->getParameters()) {
            if (argument->getName() == "") continue;
            if (argument->getTypeSpecifier() == "VOID")
                argument->setTypeSpecifier("error");
            insertToSymbolTable(argument, "Redefinition of parameter ");
        }
        argumentInfo->setParameters({});
    }

%%

int main(int argc, char* argv[]) {
    if ((fp = fopen(argv[1], "r")) == NULL) {
        printf("Cannot Open Input File.\n");
        exit(1);
    }

    logout = fopen("1905018_log.txt", "w");
    errorout = fopen("1905018_error.txt", "w");
    parseTreeOut = fopen("1905018_parseTree.txt", "w");

    yyin = fp;
    yyparse();

    fprintf(logout, "Total Lines: %d\nTotal Errors: %d\n", yylineno, errorCount);

    fclose(yyin);
    fclose(logout);
    fclose(errorout);

    return 0;
}
