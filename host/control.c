#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <errno.h>

#define XDMA_DEV "/dev/xdma0_user"

/* AXI-Lite register offsets */
#define REG0_CTRL_STATUS_OFFSET 0x0

/* slv_reg0 bit definitions */
#define CTRL_START   (1u << 0)  // write 1 to trigger
#define STAT_BUSY    (1u << 1)  // read-only
#define STAT_DONE    (1u << 2)  // sticky, cleared on START
#define CTRL_RS      (1u << 3)  // reserved

#define HBM_WR0      (1u << 4)
#define HBM_RD0      (1u << 5)
#define HBM_WR1      (1u << 6)
#define HBM_RD1      (1u << 7)

/* Reserved bits [31:8] must be 0 */
#define CTRL_ALLOWED_MASK 0x000000FFu

static int reg_write32(int fd, off_t off, uint32_t v)
{
    if (pwrite(fd, &v, sizeof(v), off) != (ssize_t)sizeof(v)) {
        return -1;
    }
    return 0;
}

static int reg_read32(int fd, off_t off, uint32_t *v)
{
    if (pread(fd, v, sizeof(*v), off) != (ssize_t)sizeof(*v)) {
        return -1;
    }
    return 0;
}

int main(void)
{
    int fd = open(XDMA_DEV, O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    uint32_t r;

    /* -------------------------------
     * Example: configure HBM selects
     *   0 = Host, 1 = TFHE_PU
     *
     * Here we route BOTH stacks read+write to TFHE_PU:
     *   WR0=1 RD0=1 WR1=1 RD1=1  => bits[7:4] = 0xF
     * Change this mask to what needs to be routed.
     * ------------------------------- */
    // uint32_t select_bits = (HBM_WR0 | HBM_RD0 | HBM_WR1 | HBM_RD1);


    uint32_t select_bits = (HBM_WR1 | HBM_RD1 | HBM_WR1 | HBM_RD1);

    /* Write initial control value (no START yet). Keep reserved bits 0. */
    uint32_t ctrl = (select_bits & CTRL_ALLOWED_MASK);
    if (reg_write32(fd, REG0_CTRL_STATUS_OFFSET, ctrl) != 0) {
        perror("pwrite ctrl");
        close(fd);
        return 1;
    }

    if (reg_read32(fd, REG0_CTRL_STATUS_OFFSET, &r) != 0) {
        perror("pread ctrl");
        close(fd);
        return 1;
    }
    printf("CTRL/STATUS [0x%02X] = 0x%08x\n", REG0_CTRL_STATUS_OFFSET, r);

    /* -------------------------------
     * Trigger START (write 1 to bit0).
     * Note: DONE is sticky but cleared on START by HW.
     * Keep reserved bits 0.
     * ------------------------------- */
    ctrl = (select_bits | CTRL_START) & CTRL_ALLOWED_MASK;
    if (reg_write32(fd, REG0_CTRL_STATUS_OFFSET, ctrl) != 0) {
        perror("pwrite start");
        close(fd);
        return 1;
    }

    /* Optional: if START is treated as a pulse, we can deassert it. */
    ctrl = (select_bits) & CTRL_ALLOWED_MASK;
    if (reg_write32(fd, REG0_CTRL_STATUS_OFFSET, ctrl) != 0) {
        perror("pwrite deassert start");
        close(fd);
        return 1;
    }

    /* -------------------------------
     * Poll until DONE=1 (or BUSY deasserts)
     * ------------------------------- */
    // printf("Polling for DONE...\n");
    // for (;;) {
    //     if (reg_read32(fd, REG0_CTRL_STATUS_OFFSET, &r) != 0) {
    //         perror("pread poll");
    //         close(fd);
    //         return 1;
    //     }

    //     uint32_t busy = (r & STAT_BUSY) ? 1u : 0u;
    //     uint32_t done = (r & STAT_DONE) ? 1u : 0u;

    //     printf("\rCTRL/STATUS = 0x%08x  (BUSY=%u DONE=%u)   ", r, busy, done);
    //     fflush(stdout);

    //     if (done) {
    //         printf("\nDONE observed.\n");
    //         break;
    //     }

    //     /* Don’t hammer AXI-Lite too hard */
    //     usleep(1000);
    // }

    close(fd);
    return 0;
}
