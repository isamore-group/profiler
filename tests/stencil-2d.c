#define ROW_SIZE 32
#define COL_SIZE 32
#define F_SIZE 9
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
int N;

__attribute__((noinline))
void stencil_2d(float orig_in[ROW_SIZE * COL_SIZE], float sol_out[ROW_SIZE * COL_SIZE], float filter_in[F_SIZE]){
    for (int r=0; r<ROW_SIZE-2; r++) {
        for (int c=0; c<COL_SIZE-2; c++) {
            float temp = 0;
            for (int k1=0;k1<3;k1++){
                for (int k2=0;k2<3;k2++){
                    float mul = filter_in[k1*3 + k2] * orig_in[(r+k1)*COL_SIZE + c+k2];
                    temp += mul;
                }
            }
            sol_out[(r*COL_SIZE) + c] = temp;
        }
    }
label_end:
  return;
}

int main() {
    srand(time(NULL));
    float orig_in[ROW_SIZE * COL_SIZE];
    float sol_out[ROW_SIZE * COL_SIZE] = {0};
    float filter_in[F_SIZE];
    for (int i = 0; i < ROW_SIZE * COL_SIZE; i++) {
        orig_in[i] = rand();
    }
    for (int i = 0; i < F_SIZE; i++) {
        filter_in[i] = rand();
    }
    stencil_2d(orig_in, sol_out, filter_in);
    int m = rand() % ROW_SIZE;
    int n = rand() % COL_SIZE;
    printf("sol_out[%d][%d] = %f\n", m, n, sol_out[m*COL_SIZE + n]);
    return 0;
}