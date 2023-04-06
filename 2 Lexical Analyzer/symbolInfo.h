#include <iostream>
using namespace std;

class SymbolInfo {
    // entry of hash value
   private:
    /* data */
    string name, type;
    SymbolInfo* prev;
    SymbolInfo* next;

   public:
    SymbolInfo(string name, string type);
    ~SymbolInfo();

    string getName() { return name; }
    string getType() { return type; }
    SymbolInfo* getPrev() { return prev; }
    SymbolInfo* getNext() { return next; }

    void setName(string s) { name = s; }
    void setType(string s) { type = s; }
    void setPrev(SymbolInfo* prev) { this->prev = prev; }
    void setNext(SymbolInfo* next) { this->next = next; }

    string print() {
        return "<" + name + "," + type + "> ";
    }
};

SymbolInfo::SymbolInfo(string name, string type) {
    this->name = name;
    this->type = type;
    this->next = nullptr;
    this->prev = nullptr;
}

SymbolInfo::~SymbolInfo() {}
