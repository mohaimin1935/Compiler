int w[10];
int main() {
    int i, x[10];
    w[0] = -2;
    x[0] = w[0];
    i = x[0];
    println(i);  // -2
    x[1] = w[0]++;
    i = x[1];
    println(i);  // -1
    i = w[0];
    println(i);  // -1

    i = i + 0;
    i = i - 0;
    i = i * 1;
    println(i);  // -1

    if ((i > 0 && i < 10) || (i < 0 && i > -10))
        i = 100;
    else
        i = 200;
    println(i);  // 100

    return 0;
}
