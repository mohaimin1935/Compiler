#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <iostream>

#include "classes/symbolInfo.h"
#include "classes/symbolTable.h"

using namespace std;

extern FILE* parseTreeOut;
extern FILE* assemblyCodeOut;
extern SymbolInfo* globalVarInfo;
extern SymbolTable* symbolTable;
extern int labelCount;
extern int stackBufferOffset;

int globalArrayOffset = 0;

string newLineProc =
    "new_line PROC\n\
\tPUSH AX\n\
\tPUSH DX\n\
\tMOV AH, 2\n\
\tMOV DL, CR\n\
\tINT 21H\n\
\tMOV AH, 2\n\
\tMOV DL, LF\n\
\tINT 21H\n\
\tPOP DX\n\
\tPOP AX\n\
\tRET\n\
new_line ENDP\n";

string printOutputProc =
    "print_output PROC\n\
\tPUSH AX\n\
\tPUSH CX\n\
\tPUSH DX\n\
\tPUSH SI\n\
\tLEA SI,NUMBER\n\
\tADD SI,4\n\
\tCMP AX,0\n\
\tJNGE NEGATE\n\
PRINT:\n\
\tXOR DX,DX\n\
\tDIV TEN\n\
\tMOV [SI],DL\n\
\tADD [SI],'0'\n\
\tDEC SI\n\
\tCMP AX,0\n\
\tJNE PRINT\n\
\tINC SI\n\
\tLEA DX,SI\n\
\tMOV AH,9\n\
\tINT 21H\n\
\tPOP SI\n\
\tPOP DX\n\
\tPOP CX\n\
\tPOP AX\n\
\tRET\n\
NEGATE:\n\
\tPUSH AX\n\
\tMOV AH,02H\n\
\tMOV DL,'-'\n\
\tINT 21H\n\
\tPOP AX\n\
\tNEG AX\n\
\tJMP PRINT\n\
print_output ENDP\n";

void preOrderParaseTree(SymbolInfo* head);
void generateCode(SymbolInfo* head);
bool matchRule(SymbolInfo* head, string rule);
void trim(string& s);
void printLabel(int label);
int newLabel();
void printCode(string s);
void printJump(string jump, int label);
void printMovBpAx(SymbolInfo* var);
void printMovAxBp(SymbolInfo* var);

void preOrderParaseTree(SymbolInfo* head) {
    fprintf(parseTreeOut, head->printNode().c_str());
    for (auto child : head->getChildren()) {
        child->setDepth(head->getDepth() + 1);
        preOrderParaseTree(child);
    }
}

void trim(string& s) {
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), [](int ch) {
                return !std::isspace(ch);
            }));
    s.erase(std::find_if(s.rbegin(), s.rend(), [](int ch) {
                return !std::isspace(ch);
            }).base(),
            s.end());
}

bool matchRule(SymbolInfo* head, string rule) {
    string r = head->getSType() + " : ";
    for (auto right : head->getChildren()) {
        r += (right->getSType() + " ");
    }

    trim(r);
    trim(rule);

    return (rule == r);
}

bool isGlobalVar(SymbolInfo* var) {
    auto globalVars = globalVarInfo->getDeclarations();
    return find(globalVars.begin(), globalVars.end(), var) != globalVars.end();
}

void printCode(string s) {
    fprintf(assemblyCodeOut, s.c_str());
}

void printLabel(int label = -1) {
    if (label == -1)
        printCode("L" + to_string(newLabel()) + ":\n");
    else
        printCode("L" + to_string(label) + ":\n");
}

void printJump(string jump, int label) {
    printCode("\t" + jump + " L" + to_string(label) + "\n");
}

void printMovBpAx(SymbolInfo* var) {
    if (var->stackBuffer > 0) {
        printCode("\tMOV [BP-" + to_string(var->stackBuffer) + "], AX\n");
    } else {
        printCode("\tMOV [BP+" + to_string(-var->stackBuffer) + "], AX\n");
    }
}

void printMovAxBp(SymbolInfo* var) {
    if (var->stackBuffer > 0) {
        printCode("\tMOV AX, [BP-" + to_string(var->stackBuffer) + "]\n");
    } else {
        printCode("\tMOV AX, [BP+" + to_string(-var->stackBuffer) + "]\n");
    }
}

int newLabel() { return labelCount++; }

void generateCode(SymbolInfo* head) {
    auto children = head->getChildren();

    // start : program
    if (matchRule(head, "start : program")) {
        printCode(".MODEL SMALL\n.STACK 1000H\n.DATA\n\tCR EQU 0DH\n\tLF EQU 0AH\n\tNUMBER DB \"00000$\"\n");
        for (auto globalVar : globalVarInfo->getDeclarations()) {
            if (globalVar->isArray()) {
                // TODO: handle array as global variable (?)
                printCode("\t" + globalVar->getName() + " DW 0\n");
            } else {
                printCode("\t" + globalVar->getName() + " DW 0\n");
            }
        }
        printCode("\tTEN DW 10\n");
        printCode(".CODE\n");
        generateCode(children[0]);

        // new_line PROC
        printCode(newLineProc);

        // print_output PROC
        printCode(printOutputProc);
        printCode("END main\n");
    }

    // program : program unit
    if (matchRule(head, "program : program unit")) {
        generateCode(children[0]);
        generateCode(children[1]);
    }

    // program : unit
    if (matchRule(head, "program : unit")) {
        generateCode(children[0]);
    }

    // unit : var_declaration
    if (matchRule(head, "unit : var_declaration")) {
        generateCode(children[0]);
    }

    // unit : func_declaration
    if (matchRule(head, "unit : func_declaration")) {
        generateCode(children[0]);
    }

    // unit : func_definition
    if (matchRule(head, "unit : func_definition")) {
        generateCode(children[0]);
    }

    // func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    if (matchRule(head, "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON")) {
    }

    // func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON
    if (matchRule(head, "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON")) {
    }

    // func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
    if (matchRule(head, "func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement")) {
        // prev scope offset
        int tempStackBufferOffset = stackBufferOffset;
        stackBufferOffset = 0;
        children[5]->exitLabel = newLabel();

        printCode("\n" + children[1]->getName() + " PROC\n");

        // if main function
        if (children[1]->getName() == "main") {
            printCode("\tMOV AX, @DATA\n\tMOV DS, AX\n");
        }
        printCode("\tPUSH BP\n\tMOV BP, SP\n");

        generateCode(children[3]);
        generateCode(children[5]);
        printLabel(children[5]->exitLabel);
        printCode("\tADD SP, " + to_string(stackBufferOffset) + "\n");
        if (children[1]->getName() == "main") {
            printCode("\tPOP BP\n\tMOV AX, 4CH\n\tINT 21H\n");
        } else {
            printCode("\tMOV SP, BP\n\tPOP BP\n\tRET\n");
        }

        printCode(children[1]->getName() + " ENDP\n");
        stackBufferOffset = tempStackBufferOffset;
    }

    // func_definition : type_specifier ID LPAREN RPAREN compound_statement
    if (matchRule(head, "func_definition : type_specifier ID LPAREN RPAREN compound_statement")) {
        int tempStackBufferOffset = stackBufferOffset;
        stackBufferOffset = 0;
        children[4]->exitLabel = newLabel();

        printCode("\n" + children[1]->getName() + " PROC\n");

        // if main function
        if (children[1]->getName() == "main") {
            printCode("\tMOV AX, @DATA\n\tMOV DS, AX\n");
        }
        printCode("\tPUSH BP\n\tMOV BP, SP\n");

        generateCode(children[4]);
        printLabel(children[4]->exitLabel);
        printCode("\tADD SP, " + to_string(stackBufferOffset) + "\n");
        if (children[1]->getName() == "main") {
            printCode("\tPOP BP\n\tMOV AX, 4CH\n\tINT 21H\n");
        } else {
            printCode("\tMOV SP, BP\n\tPOP BP\n\tRET\n");
        }

        printCode(children[1]->getName() + " ENDP\n");
        stackBufferOffset = tempStackBufferOffset;
    }

    // parameter_list : parameter_list COMMA type_specifier ID
    if (matchRule(head, "parameter_list : parameter_list COMMA type_specifier ID")) {
        // TODO: handle array as parameter (?)
        generateCode(children[0]);
        if (children[3]->isArray()) {
            head->stackBuffer = children[0]->stackBuffer - 2 * children[3]->getSize();
            children[3]->stackBuffer = children[0]->stackBuffer - 2;
        } else {
            children[3]->stackBuffer = children[0]->stackBuffer - 2;
            head->stackBuffer = children[3]->stackBuffer;
        }
    }

    // parameter_list : parameter_list COMMA type_specifier
    if (matchRule(head, "parameter_list : parameter_list COMMA type_specifier")) {
    }

    // parameter_list : type_specifier ID
    if (matchRule(head, "parameter_list : type_specifier ID")) {
        // TODO: handle array (?)
        // 2 for return pointer, 2 extra
        children[1]->stackBuffer = -4;
        head->stackBuffer = children[1]->stackBuffer;
    }

    // parameter_list : type_specifier
    if (matchRule(head, "parameter_list : type_specifier")) {
    }

    // compound_statement : LCURL statements RCURL
    if (matchRule(head, "compound_statement : LCURL statements RCURL")) {
        children[1]->exitLabel = head->exitLabel;
        generateCode(children[1]);
    }

    // compound_statement : LCURL RCURL
    if (matchRule(head, "compound_statement : LCURL RCURL")) {
    }

    // var_declaration : type_specifier declaration_list SEMICOLON
    if (matchRule(head, "var_declaration : type_specifier declaration_list SEMICOLON")) {
        for (auto var : children[1]->getDeclarations()) {
            // var is not a global variable
            if (!isGlobalVar(var)) {
                if (var->isArray()) {
                    int size = 2 * var->getSize();
                    printCode("\tSUB SP, " + to_string(size) + "\n");
                    var->stackBuffer = stackBufferOffset + 2;
                    stackBufferOffset += size;
                } else {
                    printCode("\tSUB SP, 2\n");
                    stackBufferOffset += 2;
                    var->stackBuffer = stackBufferOffset;
                }
            } else {
                if (var->isArray()) {
                    var->stackBuffer = globalArrayOffset;
                    globalArrayOffset += (2 * var->getSize());
                }
            }
        }
    }

    // type_specifier : INT
    if (matchRule(head, "type_specifier : INT")) {
    }

    // type_specifier : FLOAT
    if (matchRule(head, "type_specifier : FLOAT")) {
    }

    // type_specifier : VOID
    if (matchRule(head, "type_specifier : VOID")) {
    }

    // declaration_list : declaration_list COMMA ID
    if (matchRule(head, "declaration_list : declaration_list COMMA ID")) {
    }

    // declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE
    if (matchRule(head, "declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE")) {
    }

    // declaration_list : ID
    if (matchRule(head, "declaration_list : ID")) {
    }

    // declaration_list : ID LSQUARE CONST_INT RSQUARE
    if (matchRule(head, "declaration_list : ID LSQUARE CONST_INT RSQUARE")) {
    }

    // statements : statement
    if (matchRule(head, "statements : statement")) {
        children[0]->exitLabel = head->exitLabel;
        generateCode(children[0]);
    }

    // statements : statements statement
    if (matchRule(head, "statements : statements statement")) {
        children[0]->exitLabel = head->exitLabel;
        children[1]->exitLabel = head->exitLabel;
        generateCode(children[0]);
        generateCode(children[1]);
    }

    // statement : var_declaration
    if (matchRule(head, "statement : var_declaration")) {
        printCode("; var_declaration: line-" + to_string(head->getEndLine()) + "\n");
        generateCode(children[0]);
    }

    // statement : expression_statement
    if (matchRule(head, "statement : expression_statement")) {
        // printCode("; evaluating expression: line-" + to_string(head->getEndLine()) + "\n");
        generateCode(children[0]);
    }

    // statement : compound_statement
    if (matchRule(head, "statement : compound_statement")) {
        children[0]->exitLabel = head->exitLabel;
        generateCode(children[0]);
    }

    // statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement
    if (matchRule(head, "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement")) {
        int loopLabel = newLabel();
        int nextLabel = newLabel();
        children[6]->exitLabel = head->exitLabel;

        printCode("; for loop: line-" + to_string(head->getStartLine()) + "\n");

        generateCode(children[2]);
        printLabel(loopLabel);
        generateCode(children[3]);
        printCode("\tCMP AX, 0\n");
        printJump("JE", nextLabel);
        generateCode(children[6]);
        generateCode(children[4]);
        printJump("JMP", loopLabel);
        printLabel(nextLabel);
    }

    // statement : IF LPAREN expression RPAREN statement
    if (matchRule(head, "statement : IF LPAREN expression RPAREN statement")) {
        int trueLabel = newLabel();
        int nextLabel = newLabel();
        children[4]->exitLabel = head->exitLabel;

        printCode("; if logic evaluation: line-" + to_string(head->getStartLine()) + "\n");
        generateCode(children[2]);
        printCode("\tCMP AX, 0\n");
        printJump("JE", nextLabel);
        printCode("; if statement: line-" + to_string(head->getStartLine()) + "\n");
        printLabel(trueLabel);
        generateCode(children[4]);
        printLabel(nextLabel);
    }

    // statement : IF LPAREN expression RPAREN statement ELSE statement
    if (matchRule(head, "statement : IF LPAREN expression RPAREN statement ELSE statement")) {
        int trueLabel = newLabel();
        int falseLabel = newLabel();
        int nextLabel = newLabel();
        children[4]->exitLabel = head->exitLabel;
        children[6]->exitLabel = head->exitLabel;

        printCode("; if logic evaluation: line-" + to_string(head->getStartLine()) + "\n");
        generateCode(children[2]);
        printCode("\tCMP AX, 0\n");
        printJump("JE", falseLabel);
        printCode("; if statement: line-" + to_string(head->getStartLine()) + "\n");
        printLabel(trueLabel);
        generateCode(children[4]);
        printJump("JMP", nextLabel);
        printCode("; else statement: line-" + to_string(head->getStartLine()) + "\n");
        printLabel(falseLabel);
        generateCode(children[6]);
        printLabel(nextLabel);
    }

    // statement : WHILE LPAREN expression RPAREN statement
    if (matchRule(head, "statement : WHILE LPAREN expression RPAREN statement")) {
        int loopLabel = newLabel();
        int nextLabel = newLabel();
        children[4]->exitLabel = head->exitLabel;

        printCode("; while loop: line-" + to_string(head->getStartLine()) + "\n");
        printLabel(loopLabel);
        generateCode(children[2]);
        printCode("\tCMP AX, 0\n");
        printJump("JE", nextLabel);
        generateCode(children[4]);
        printJump("JMP", loopLabel);
        printLabel(nextLabel);
    }

    // statement : PRINTLN LPAREN ID RPAREN SEMICOLON
    if (matchRule(head, "statement : PRINTLN LPAREN ID RPAREN SEMICOLON")) {
        printCode("; print: line-" + to_string(head->getStartLine()) + "\n");
        if (isGlobalVar(children[2])) {
            printCode("\tMOV AX, " + children[2]->getName() + "\n\tCALL print_output\n\tCALL new_line\n");
        } else {
            printMovAxBp(children[2]);
            printCode("\tCALL print_output\n\tCALL new_line\n");
        }
    }

    // statement : RETURN expression SEMICOLON
    if (matchRule(head, "statement : RETURN expression SEMICOLON")) {
        generateCode(children[1]);
        printJump("JMP", head->exitLabel);
    }

    // expression_statement : SEMICOLON
    if (matchRule(head, "expression_statement : SEMICOLON")) {
    }

    // expression_statement : expression SEMICOLON
    if (matchRule(head, "expression_statement : expression SEMICOLON")) {
        generateCode(children[0]);
    }

    // variable : ID
    if (matchRule(head, "variable : ID")) {
        printMovAxBp(children[0]);
    }

    // variable : ID LSQUARE expression RSQUARE
    if (matchRule(head, "variable : ID LSQUARE expression RSQUARE")) {
        generateCode(children[2]);
        // BP - (stackBuffer + 2*AX)
        if (isGlobalVar(children[0])) {
            printCode("\tMOV BX, AX\n\tSHL BX, 1\n\tADD BX, " + to_string(children[0]->stackBuffer) + "\n\tNEG BX\n\tADD BX, " + children[0]->getName() + "\n");
        } else {
            printCode("\tMOV BX, AX\n\tSHL BX, 1\n\tADD BX, " + to_string(children[0]->stackBuffer) + "\n\tNEG BX\n\tADD BX, BP\n");
        }
    }

    // expression : logic_expression
    if (matchRule(head, "expression : logic_expression")) {
        generateCode(children[0]);
    }

    // expression : variable ASSIGNOP logic_expression
    if (matchRule(head, "expression : variable ASSIGNOP logic_expression")) {
        SymbolInfo* var = children[0]->getChildren()[0];

        printCode("; assignment: line-" + to_string(children[1]->getStartLine()) + "\n");
        if (isGlobalVar(var)) {
            // handle global variables
            if (var->isArray()) {
                generateCode(children[0]);
                generateCode(children[2]);
                printCode("\tMOV [BX], AX\n");
            } else {
                generateCode(children[2]);
                printCode("\tMOV " + var->getName() + ", AX\n");
            }
        } else {
            if (var->isArray()) {
                generateCode(children[0]);
                generateCode(children[2]);
                printCode("\tMOV [BX], AX\n");
            } else {
                generateCode(children[2]);
                printMovBpAx(var);
            }
        }
    }

    // logic_expression : rel_expression
    if (matchRule(head, "logic_expression : rel_expression")) {
        generateCode(children[0]);
    }

    // logic_expression : rel_expression LOGICOP rel_expression
    if (matchRule(head, "logic_expression : rel_expression LOGICOP rel_expression")) {
        int nextBoolLabel = newLabel();
        int trueLabel = newLabel();
        int falseLabel = newLabel();
        int nextLabel = newLabel();

        generateCode(children[0]);
        printCode("\tCMP AX, 0\n");

        if (children[1]->getName() == "||") {
            printJump("JNE", trueLabel);
            // printJump("JMP", nextBoolLabel);
        } else {
            printJump("JE", falseLabel);
        }

        printLabel(nextBoolLabel);
        generateCode(children[2]);
        printCode("\tCMP AX, 0\n");

        printJump("JNE", trueLabel);
        printJump("JMP", falseLabel);

        printLabel(trueLabel);
        printCode("\tMOV AX, 1\n");
        printJump("JMP", nextLabel);

        printLabel(falseLabel);
        printCode("\tMOV AX, 0\n");

        printLabel(nextLabel);
    }

    // rel_expression : simple_expression
    if (matchRule(head, "rel_expression : simple_expression")) {
        generateCode(children[0]);
    }

    // rel_expression : simple_expression RELOP simple_expression
    if (matchRule(head, "rel_expression : simple_expression RELOP simple_expression")) {
        int trueLabel = newLabel();
        int falseLabel = newLabel();
        int nextLabel = newLabel();

        generateCode(children[0]);
        printCode("\tPUSH AX\n");
        generateCode(children[2]);
        printCode("\tMOV DX, AX\n\tPOP AX\n");
        printCode("\tCMP AX, DX\n");

        string jump = "";
        if (children[1]->getName() == ">=") {
            // ax >= dx
            jump = "JGE";
        } else if (children[1]->getName() == "<=") {
            // ax <= dx
            jump = "JLE";
        } else if (children[1]->getName() == "==") {
            // ax == dx
            jump = "JE";
        } else if (children[1]->getName() == "!=") {
            // ax != dx
            jump = "JNE";
        } else if (children[1]->getName() == "<") {
            // ax < dx
            jump = "JL";
        } else {
            // ax > dx
            jump = "JG";
        }

        printJump(jump, trueLabel);
        printJump("JMP", falseLabel);

        printLabel(trueLabel);
        printCode("\tMOV AX, 1\n");
        printJump("JMP", nextLabel);
        printLabel(falseLabel);
        printCode(("\tMOV AX, 0\n"));
        printLabel(nextLabel);
    }

    // simple_expression : term
    if (matchRule(head, "simple_expression : term")) {
        generateCode(children[0]);
    }

    // simple_expression : simple_expression ADDOP term
    if (matchRule(head, "simple_expression : simple_expression ADDOP term")) {
        generateCode(children[0]);
        printCode("\tPUSH AX\n");
        generateCode(children[2]);
        printCode("\tMOV DX, AX\n\tPOP AX\n");

        if (children[1]->getName() == "+") {
            printCode("\tADD AX, DX\n");
        } else {
            printCode("\tSUB AX, DX\n");
        }
    }

    // term : unary_expression
    if (matchRule(head, "term : unary_expression")) {
        generateCode(children[0]);
    }

    // term : term MULOP unary_expression
    if (matchRule(head, "term : term MULOP unary_expression")) {
        generateCode(children[0]);
        printCode("\tPUSH AX\n");
        generateCode(children[2]);
        printCode("\tMOV CX, AX\n\tPOP AX\n");

        if (children[1]->getName() == "*") {
            printCode("\tCWD\n\tMUL CX\n");
        } else if (children[1]->getName() == "%") {
            printCode("\tCWD\n\tDIV CX\n\tMOV AX, DX\n");
        } else {
            printCode("\tCWD\n\tDIV CX\n");
        }
    }

    // unary_expression : ADDOP unary_expression
    if (matchRule(head, "unary_expression : ADDOP unary_expression")) {
        generateCode(children[1]);
        if (children[0]->getName() == "-") {
            printCode("\tNEG AX\n");
        }
    }

    // unary_expression : NOT unary_expression
    if (matchRule(head, "unary_expression : NOT unary_expression")) {
        int trueLabel = newLabel();
        int nextLabel = newLabel();

        generateCode(children[1]);
        printCode("\tCMP AX, 0\n");
        printJump("JE", trueLabel);
        printCode("\tMOV AX, 0\n");
        printJump("JMP", nextLabel);
        printLabel(trueLabel);
        printCode("\tMOV AX, 1\n");
        printLabel(nextLabel);
    }

    // unary_expression : factor
    if (matchRule(head, "unary_expression : factor")) {
        generateCode(children[0]);
    }

    // factor : variable
    if (matchRule(head, "factor : variable")) {
        auto var = children[0]->getChildren()[0];
        if (isGlobalVar(var)) {
            if (var->isArray()) {
                generateCode(children[0]);
                printCode("\tMOV AX, [BX]\n");
            } else {
                printCode("\tMOV AX, " + var->getName() + "\n");
            }
        } else {
            if (var->isArray()) {
                generateCode(children[0]);
                printCode("\tMOV AX, [BX]\n");
            } else {
                printMovAxBp(var);
            }
        }
    }

    // factor : ID LPAREN argument_list RPAREN
    if (matchRule(head, "factor : ID LPAREN argument_list RPAREN")) {
        generateCode(children[2]);
        printCode("\tCALL " + children[0]->getName() + "\n");

        for (int i = 0; i < children[2]->stackBuffer; i++) {
            printCode("\tPOP BX\n");
        }
    }

    // factor : ID LPAREN RPAREN
    if (matchRule(head, "factor : ID LPAREN RPAREN")) {
        printCode("\tCALL " + children[0]->getName() + "\n");
    }

    // factor : LPAREN expression RPAREN
    if (matchRule(head, "factor : LPAREN expression RPAREN")) {
        generateCode(children[1]);
    }

    // factor : CONST_INT
    if (matchRule(head, "factor : CONST_INT")) {
        printCode("\tMOV AX, " + children[0]->getName() + "\n");
    }

    // factor : CONST_FLOAT
    if (matchRule(head, "factor : CONST_FLOAT")) {
    }

    // factor : variable INCOP
    if (matchRule(head, "factor : variable INCOP")) {
        // FIXME: array
        SymbolInfo* var = children[0]->getChildren()[0];
        if (isGlobalVar(var)) {
            if (var->isArray()) {
                generateCode(children[0]);
                printCode("\tINC [BX]\n");
            } else {
                printCode("\tINC " + var->getName() + "\n");
            }
        } else {
            if (var->isArray()) {
                generateCode(children[0]);
                printCode("\tINC [BX]\n");
            } else {
                printMovAxBp(var);
                printCode("\tINC AX\n");
                printMovBpAx(var);
                printCode("\tDEC AX\n");
            }
        }
    }

    // factor : variable DECOP
    if (matchRule(head, "factor : variable DECOP")) {
        // FIXME: array
        SymbolInfo* var = children[0]->getChildren()[0];
        if (isGlobalVar(var)) {
            if (var->isArray()) {
                generateCode(children[0]);
                printCode("\tDEC [BX]\n");
            } else {
                printCode("\tDEC " + var->getName() + "\n");
            }
        } else {
            if (var->isArray()) {
                generateCode(children[0]);
                printCode("\tDEC [BX]\n");
            } else {
                printMovAxBp(var);
                printCode("\tDEC AX\n");
                printMovBpAx(var);
                printCode("\tINC AX\n");
            }
        }
    }

    // argument_list : arguments
    if (matchRule(head, "argument_list : arguments")) {
        generateCode(children[0]);
        head->stackBuffer = children[0]->stackBuffer;

        // keeping track of argument size in stackBuffer to pop after function call
    }

    // arguments : arguments COMMA logic_expression
    if (matchRule(head, "arguments : arguments COMMA logic_expression")) {
        generateCode(children[2]);
        printCode("\tMOV BX, AX\n\tPUSH BX\n");
        generateCode(children[0]);
        head->stackBuffer = children[0]->stackBuffer + 1;
    }

    // arguments : logic_expression
    if (matchRule(head, "arguments : logic_expression")) {
        generateCode(children[0]);
        printCode("\tMOV BX, AX\n\tPUSH BX\n");
        head->stackBuffer = 1;
    }
}
