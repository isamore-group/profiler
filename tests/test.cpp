#include <iostream>

int fibonacci(int n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n-1) + fibonacci(n-2);
}

int factorial(int n) {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n-1);
}

int main() {
    std::cout << "Fibonacci(10): " << fibonacci(10) << std::endl;
    std::cout << "Factorial(5): " << factorial(5) << std::endl;
    return 0;
} 