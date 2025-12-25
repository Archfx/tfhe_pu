#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>

#define XDMA_DEV "/dev/xdma0_user"

int main(void)
{
    int fd = open(XDMA_DEV, O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    uint32_t w, r;

    /* -------------------------------
     * Write test pattern
     * ------------------------------- */
    for (int i = 0; i < 6; i++) {
        w = 0xA5A50000 | i;
        if (pwrite(fd, &w, sizeof(w), i * 0x4) != sizeof(w)) {
            perror("pwrite");
            close(fd);
            return 1;
        }
    }

    /* -------------------------------
     * Read back and verify
     * ------------------------------- */
    for (int i = 0; i < 6; i++) {
        if (pread(fd, &r, sizeof(r), i * 0x4) != sizeof(r)) {
            perror("pread");
            close(fd);
            return 1;
        }

        printf("REG%d [0x%02X] = 0x%08x\n",
               i, i * 0x4, r);
    }

    close(fd);
    return 0;
}
