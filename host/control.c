#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <errno.h>

#define XDMA_USER_DEV "/dev/xdma0_user"

/* AXI-Lite BAR size */
#define MAP_SIZE 4096

/* Register offsets */
#define REG_CTRL     0x00
#define REG_WR_ADDR  0x04
#define REG_WR_LEN   0x08
#define REG_STATUS   0x0C
#define REG_RD_ADDR  0x10
#define REG_RD_LEN   0x14

/* CTRL bits */
#define CTRL_START   (1u << 0)

/* STATUS bits */
#define STATUS_BUSY  (1u << 0)
#define STATUS_DONE  (1u << 1)

static inline void mmio_write(volatile uint32_t *regs,
                              uint32_t offset,
                              uint32_t value)
{
    regs[offset >> 2] = value;
}

static inline uint32_t mmio_read(volatile uint32_t *regs,
                                 uint32_t offset)
{
    return regs[offset >> 2];
}

int main(int argc, char *argv[])
{
    if (argc != 3) {
        fprintf(stderr,
            "Usage: %s <wr_addr_hex> <wr_len_dec>\n"
            "Example: %s 0x80000000 4096\n",
            argv[0], argv[0]);
        return 1;
    }

    uint32_t wr_addr = strtoul(argv[1], NULL, 0);
    uint32_t wr_len  = strtoul(argv[2], NULL, 0);

    int fd = open(XDMA_USER_DEV, O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("open xdma user");
        return 1;
    }

    void *map = mmap(NULL, MAP_SIZE,
                     PROT_READ | PROT_WRITE,
                     MAP_SHARED, fd, 0);
    if (map == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return 1;
    }

    volatile uint32_t *regs = (volatile uint32_t *)map;

    /* --------------------------------------------------
     * Program accelerator
     * -------------------------------------------------- */
    mmio_write(regs, REG_WR_ADDR, wr_addr);
    mmio_write(regs, REG_WR_LEN,  wr_len);

    /* Kick accelerator (W1P) */
    mmio_write(regs, REG_CTRL, CTRL_START);

    printf("Started PBS\n");
    printf("  WR_ADDR = 0x%08x\n", wr_addr);
    printf("  WR_LEN  = %u\n", wr_len);

    /* --------------------------------------------------
     * Poll status (simple version)
     * -------------------------------------------------- */
    // uint32_t status;
    // do {
    //     status = mmio_read(regs, REG_STATUS);
    // } while (status & STATUS_BUSY);

    // if (status & STATUS_DONE) {
    //     uint32_t rd_addr = mmio_read(regs, REG_RD_ADDR);
    //     uint32_t rd_len  = mmio_read(regs, REG_RD_LEN);

    //     printf("PBS done\n");
    //     printf("  RD_ADDR = 0x%08x\n", rd_addr);
    //     printf("  RD_LEN  = %u\n", rd_len);
    // } else {
    //     printf("Unexpected status: 0x%08x\n", status);
    // }

    munmap(map, MAP_SIZE);
    close(fd);
    return 0;
}
