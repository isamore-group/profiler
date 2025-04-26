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
label0:
  int x = a[0], y = a[n-1], z = a[n/2];
  int ans = (x<<1) + (y*3) + (z/2);
  printf("a[1] = %d\na[%d] = %d\na[%d] = %d\nans = %d\n", a[1], n - 1, a[n - 1], n/2, a[n/2], ans);
  return 0;
}
