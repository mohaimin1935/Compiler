#ifndef SYMBOL_INFO
#define SYMBOL_INFO

#include <iostream>
#include <set>
#include <vector>

using namespace std;

const set<string> terminals{
    "IF",
    "ELSE",
    "FOR",
    "WHILE",
    "DO",
    "BREAK",
    "INT",
    "CHAR",
    "FLOAT",
    "DOUBLE",
    "VOID",
    "RETURN",
    "SWITCH",
    "CASE",
    "DEFAULT",
    "CONTINUE",
    "CONST_INT",
    "CONST_FLOAT",
    "CONST_CHAR",
    "INCOP",
    "LOGICOP",
    "ADDOP",
    "MULOP",
    "RELOP",
    "ASSIGNOP",
    "BITOP",
    "NOT",
    "LPAREN",
    "RPAREN",
    "LCURL",
    "RCURL",
    "LSQUARE",
    "RSQUARE",
    "COMMA",
    "SEMICOLON",
    "ID",
    "PRINTLN",
    "DECOP",
    "THEN",
    "error"};

class SymbolInfo {
    // entry of hash value
   private:
    /* data */
    string name = "", type = "", returnType = "", typeSpecifier = "", sType = "";
    SymbolInfo* prev = nullptr;
    SymbolInfo* next = nullptr;

    bool functionDefinition = false;
    bool functionDeclaration = false;
    bool array = false;
    int size = 0;
    vector<SymbolInfo*> declarations = {};
    vector<SymbolInfo*> parameters = {};

    // variables for building parse tree
    SymbolInfo* parent = nullptr;
    vector<SymbolInfo*> children = {};
    int depth = 0;
    bool leaf = false;
    int startLine = 0, endLine = 0;

   public:
    SymbolInfo(string name = "", string type = "", string typeSpecifier = "", string returnType = "", int size = 0) {
        this->name = name;
        this->type = type;
        this->sType = type;
        this->typeSpecifier = typeSpecifier;
        this->returnType = returnType;
        this->size = size;
        this->next = nullptr;
        this->prev = nullptr;

        if (terminals.count(type)) {
            this->leaf = true;
        }
    }
    SymbolInfo(SymbolInfo* symbolInfo) {
        name = symbolInfo->name;
        type = symbolInfo->type;
        sType = symbolInfo->sType;
        returnType = symbolInfo->returnType;
        typeSpecifier = symbolInfo->typeSpecifier;
        prev = symbolInfo->prev;
        next = symbolInfo->next;
        functionDeclaration = symbolInfo->functionDeclaration;
        functionDefinition = symbolInfo->functionDefinition;
        array = symbolInfo->array;
        declarations = symbolInfo->declarations;
        parameters = symbolInfo->parameters;
    }

    ~SymbolInfo() {}

    string getName() { return name; }
    string getType() { return type; }
    string getReturnType() { return returnType; }
    string getTypeSpecifier() { return typeSpecifier; }
    int getSize() { return size; }
    SymbolInfo* getPrev() { return prev; }
    SymbolInfo* getNext() { return next; }

    void setFunctionDefinition(bool value) { functionDefinition = value; }
    void setFunctionDeclaration(bool value) { functionDeclaration = value; }
    void setArray(bool value) { array = value; }

    void setName(string s) { name = s; }
    void setType(string s) {
        // TODO:
        type = s;
        if (s == "INT" || s == "FLOAT" || s == "DOUBLE") {
            typeSpecifier = s;
        }
        if (s == "error") leaf = true;
    }
    void setReturnType(string s) {
        returnType = s;
        typeSpecifier = s;
    }
    void setTypeSpecifier(string s) { typeSpecifier = s; }
    void setSize(int s) { size = s; }
    void setPrev(SymbolInfo* prev) { this->prev = prev; }
    void setNext(SymbolInfo* next) { this->next = next; }

    bool isFunctionDefinition() { return functionDefinition; }
    bool isFunctionDeclaration() { return functionDeclaration; }
    bool isArray() { return array; }

    void pushDeclaration(SymbolInfo* declaration) { declarations.push_back(declaration); }
    vector<SymbolInfo*> getDeclarations() { return declarations; }
    void setDeclarations(vector<SymbolInfo*> declarations) { this->declarations = declarations; }

    void pushParameter(SymbolInfo* parameter) { parameters.push_back(parameter); }
    vector<SymbolInfo*> getParameters() { return parameters; }
    void setParameters(vector<SymbolInfo*> parameters) { this->parameters = parameters; }

    // functions for building parse tree
    void setParent(SymbolInfo* parent) { this->parent = parent; }
    void setChildren(vector<SymbolInfo*> children) {
        this->children = children;
        if (children.size() > 0) {
            endLine = children[children.size() - 1]->endLine;
        }
    }
    void setDepth(int depth) { this->depth = depth; }
    void setLeaf(bool leaf) { this->leaf = leaf; }
    void setStartLine(int line) {
        this->startLine = line;
        if (leaf) {
            this->endLine = line;
        }
    }
    void setEndLine(int line) { this->endLine = line; }

    void pushChild(SymbolInfo* child) {
        children.push_back(child);
        this->setEndLine(child->endLine);
    }

    int getDepth() { return depth; }
    bool isLeaf() { return leaf; }
    int getStartLine() { return startLine; }
    int getEndLine() { return endLine; }
    vector<SymbolInfo*> getChildren() { return children; }

    string printNode() {
        string returnString = "";
        // TODO: handle indentation
        for (int i = 0; i < depth; i++) returnString += " ";

        returnString += (this->sType + " :");
        if (leaf) returnString += (" " + this->name);
        for (auto child : children) {
            returnString += (" " + child->sType);
        }

        if (leaf)
            returnString += ("\t<Line: " + to_string(startLine) + ">\n");
        else
            returnString += (" \t<Line: " + to_string(startLine) + "-" + to_string(endLine) + ">\n");

        return returnString;
    }

    string print() {
        if (functionDeclaration || functionDefinition) {
            return ("<" + this->getName() + ", " + this->getType() + ", " + this->getReturnType() + "> ");
        }

        if (array) {
            return ("<" + this->getName() + ", ARRAY, " + this->getType() + "> ");
        }

        return ("<" + this->getName() + ", " + this->getType() + "> ");
    }

    void printAll() {
        cout << "\n\nname: " << this->getName() << "\ntype: " << this->getType() << "\nreturn: " << this->returnType << "\ntypeSpec: " << this->getTypeSpecifier() << "\nsize: " << to_string(this->getSize()) << "\nfunc_dec: " << this->isFunctionDeclaration() << "\nfunc_def: " << this->isFunctionDefinition() << "\narray: " << this->isArray() << "\nparams: ";

        for (auto x : this->getParameters()) {
            cout << x->getName() << " ";
        }
        cout << "\ndec_list: ";
        for (auto x : this->getDeclarations()) {
            cout << x->getName() << " ";
        }

        cout << "\n\n";
    }
};

#endif