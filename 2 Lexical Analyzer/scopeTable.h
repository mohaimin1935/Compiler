#include "symbolInfo.h"
using namespace std;

class ScopeTable {
    // basically the implementation of a hash table
    // doubly-linked-list in seperate chaining
   private:
    /* data */
    SymbolInfo** scopeTable;
    ScopeTable* parentScope;
    int id, N;

    /* methods */
    static unsigned long long SDBMHash(string str, int N) {
        unsigned long long hash = 0;
        unsigned int i = 0;
        unsigned int len = str.length();

        for (i = 0; i < len; i++) {
            hash = (str[i]) + (hash << 6) + (hash << 16) - hash;
        }

        return hash % N;
    }

    unsigned int hashFunction(string name) {
        return (unsigned long long)(SDBMHash(name, N) % N);
    }

   public:
    ScopeTable(int n, int id);
    ~ScopeTable();

    void setId(int id) {
        this->id = id;
    }
    void setParentScope(ScopeTable* parent) {
        this->parentScope = parent;
    }

    int getId() { return this->id; }
    ScopeTable* getParentScope() { return this->parentScope; }

    bool insert(string name, string type) {
        unsigned int hashValue = hashFunction(name);
        int position = 1;
        SymbolInfo* symbolInfo = scopeTable[hashValue];
        SymbolInfo* prevSymbolInfo = symbolInfo;

        if (symbolInfo == nullptr) {
            // first element with this hash
            symbolInfo = new SymbolInfo(name, type);
            scopeTable[hashValue] = symbolInfo;
        } else {
            // name already exists, add to tail
            if (symbolInfo->getName() == name) {
                // cout << "\t'" << name << "' already exists in the current ScopeTable\n";
                return false;
            }

            position++;
            SymbolInfo* newSymbolInfo = new SymbolInfo(name, type);
            while (symbolInfo != nullptr) {
                if (symbolInfo->getName() == name) {
                    // cout << "\t'" << name << "' already exists in the current ScopeTable\n";
                    return false;
                }
                position++;
                prevSymbolInfo = symbolInfo;
                symbolInfo = symbolInfo->getNext();
            }
            symbolInfo = prevSymbolInfo;
            newSymbolInfo->setPrev(symbolInfo);
            symbolInfo->setNext(newSymbolInfo);
        }
        // cout << "\tInserted in ScopeTable# " << id << " at position " << (hashValue + 1) << ", " << position << endl;
        return true;
    }

    SymbolInfo* lookup(string name) {
        unsigned int hashValue = hashFunction(name);
        int position = 1;
        SymbolInfo* symbolInfo = scopeTable[hashValue];

        while (symbolInfo != nullptr) {
            if (symbolInfo->getName() == name) {
                // cout << "\t'" << name << "' found in ScopeTable# " << id << " at position " << (hashValue + 1) << ", " << position << endl;
                return symbolInfo;
            }
            position++;
            symbolInfo = symbolInfo->getNext();
        }

        return nullptr;
    }

    bool deleteEntry(string name) {
        unsigned int hashValue = hashFunction(name);
        int position = 1;
        SymbolInfo* symbolInfo = scopeTable[hashValue];

        while (symbolInfo != nullptr) {
            if (symbolInfo->getName() == name) {
                if (symbolInfo->getNext() != nullptr) {
                    // **(*)*
                    symbolInfo->getNext()->setPrev(symbolInfo->getPrev());
                }

                if (symbolInfo->getPrev() != nullptr) {
                    // **(*)*
                    symbolInfo->getPrev()->setNext(symbolInfo->getNext());
                } else {
                    // (*)** || (*)
                    scopeTable[hashValue] = symbolInfo->getNext();
                }

                delete symbolInfo;
                // cout << "\tDeleted '" << name << "' from ScopeTable# " << id << " at position " << (hashValue + 1) << ", " << position << endl;
                return true;
            }
            position++;
            symbolInfo = symbolInfo->getNext();
        }

        // cout << "\tNot found in the current ScopeTable\n";
        return false;
    }

    string print() {
        string ret = "\tScopeTable# " + to_string(id) + "\n";

        for (int i = 0; i < N; i++) {
            SymbolInfo* symbolInfo = scopeTable[i];
            bool notNull = false;
            if (symbolInfo != nullptr) {
                ret += ("\t" + to_string(i + 1) + "--> ");
                notNull = true;
            }
            while (symbolInfo != nullptr) {
                ret += symbolInfo->print();
                symbolInfo = symbolInfo->getNext();
            }
            if (notNull) ret += "\n";
        }
        return ret;
    }
};

ScopeTable::ScopeTable(int n, int id) {
    this->id = id;
    N = n;
    scopeTable = new SymbolInfo*[n];
    parentScope = nullptr;

    for (int i = 0; i < n; i++) {
        scopeTable[i] = nullptr;
    }

    // cout << "\tScopeTable# " << id << " created" << endl;
}

ScopeTable::~ScopeTable() {
    // cout << "\tScopeTable# " << id << " removed";
    if (id != 1) {
        // cout << endl;
    }
    delete[] scopeTable;
}