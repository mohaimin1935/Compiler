#include "scopeTable.h"
using namespace std;

class SymbolTable {
    // stack of hash tables
   private:
    /* data */
    int bucketSize;
    ScopeTable* currentScope;
    ScopeTable** scopeStack;
    int scopeCount;

   public:
    SymbolTable(int bucketSize);
    ~SymbolTable();

    void enterScope() {
        ScopeTable* temp = new ScopeTable(bucketSize, ++scopeCount);

        if (currentScope == nullptr) {
            currentScope = temp;
        } else {
            temp->setParentScope(currentScope);
            currentScope = temp;
        }
    }

    void exitScope() {
        if (currentScope->getId() == 1) {
            cout << "\tScopeTable# 1 cannot be removed\n";
            return;
        }

        ScopeTable* temp = currentScope;
        currentScope = currentScope->getParentScope();
        delete temp;
    }

    void deleteAllScope() {
        while (currentScope != nullptr) {
            ScopeTable* temp = currentScope;
            currentScope = currentScope->getParentScope();
            delete temp;
        }
    }

    void insert(string name, string type) {
        currentScope->insert(name, type);
    }

    bool remove(string name) {
        return currentScope->deleteEntry(name);
    }

    SymbolInfo* lookup(string name) {
        ScopeTable* temp = currentScope;

        while (temp != nullptr) {
            SymbolInfo* tempInfo = temp->lookup(name);
            if (tempInfo != nullptr) {
                return tempInfo;
            }
            temp = temp->getParentScope();
        }
        cout << "\t'" << name << "' not found in any of the ScopeTables" << endl;
        return nullptr;
    }

    void printCurrentScope() {
        currentScope->print();
    }

    void printAllScope() {
        ScopeTable* temp = currentScope;

        while (temp != nullptr) {
            temp->print();
            temp = temp->getParentScope();
        }
    }
};

SymbolTable::SymbolTable(int bucketSize) {
    scopeCount = 0;
    currentScope = nullptr;
    this->bucketSize = bucketSize;
}

SymbolTable::~SymbolTable() {
    delete currentScope;
    delete[] scopeStack;
}
