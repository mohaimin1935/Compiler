#include <fstream>
#include <string>

#include "symbolTable.h"

// g++ main.cpp -o main && ./main > output.txt

using namespace std;

string getParam(int x, string line) {
    // expected line format: A Bcd Efg
    // x = 1: Bcd, x = 2: Efg
    string param = "";
    for (int i = 0; i < line.length(); i++) {
        if (x && line[i] == ' ') {
            x--;
        } else if (!x && (line[i] == ' ' || line[i] == '\0')) {
            return param;
        } else if (!x) {
            param += line[i];
        }
    }
    return param;
}

int main() {
    ifstream input("input.txt");
    freopen("output.txt", "w", stdout);

    if (input.is_open()) {
        string line;
        getline(input, line);
        int bucketSize = stoi(line);

        SymbolTable* symbolTable = new SymbolTable(bucketSize);
        symbolTable->enterScope();

        int cmdCount = 0;
        while (getline(input, line)) {
            cmdCount++;
            cout << "Cmd " << cmdCount << ": " << line << "\n";

            string param1, param2;
            char command = line[0];
            param1 = getParam(1, line);
            param2 = getParam(2, line);

            if (command == 'Q') {
                symbolTable->deleteAllScope();
                break;
            }

            switch (command) {
                case 'I':
                    if (param1 == "" || param2 == "") {
                        cout << "\tNumber of parameters mismatch for the command I\n";
                        break;
                    }
                    symbolTable->insert(param1, param2);
                    break;

                case 'L':
                    if (param1 == "" || param2 != "") {
                        cout << "\tNumber of parameters mismatch for the command L\n";
                        break;
                    }
                    symbolTable->lookup(param1);
                    break;

                case 'D':
                    if (param1 == "" || param2 != "") {
                        cout << "\tNumber of parameters mismatch for the command D\n";
                        break;
                    }
                    symbolTable->remove(param1);
                    break;

                case 'P':
                    if (param1 == "" || param2 != "") {
                        cout << "\tNumber of parameters mismatch for the command P\n";
                        break;
                    }
                    if (param1 == "C") {
                        symbolTable->printCurrentScope();
                    } else if (param1 == "A") {
                        symbolTable->printAllScope();
                    }
                    break;

                case 'S':
                    if (param1 != "" || param2 != "") {
                        cout << "\tNumber of parameters mismatch for the command S\n";
                        break;
                    }
                    symbolTable->enterScope();
                    break;

                case 'E':
                    if (param1 != "" || param2 != "") {
                        cout << "\tNumber of parameters mismatch for the command E\n";
                        break;
                    }
                    symbolTable->exitScope();
                    break;

                default:
                    break;
            }
        }
    }

    return 0;
}