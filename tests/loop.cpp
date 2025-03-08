#include <cstdio>
#include <cstdlib>

int main(int argc, char **argv) {
  int n;
  sscanf(argv[1], "%d", &n);
  int a[n];
  for (int i = 0; i < n; i++) {
    a[i] = i;
  }
  for (int i = 0; i < n; i++) {
    int sum = a[i];
    for (int j = 0; j < n; j++) {
      sum += a[j];
    }
    a[i] = sum;
  }
  printf("a[1] = %d\na[%d] = %d\n", a[1], n - 1, a[n - 1]);
  return 0;
}
