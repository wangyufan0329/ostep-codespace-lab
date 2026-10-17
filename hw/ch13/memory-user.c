#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: memory-user <megabytes>\n");
        exit(1);
    }
    long mb = atol(argv[1]);
    size_t size = (size_t) mb * 1024 * 1024;
    char *arr = malloc(size);
    if (arr == NULL) {
        fprintf(stderr, "malloc failed\n");
        exit(1);
    }
    printf("pid %d: using %ld MB\n", getpid(), mb);
    while (1) {
        for (size_t i = 0; i < size; i++) {
            arr[i] += 1;
        }
    }
    return 0;
}