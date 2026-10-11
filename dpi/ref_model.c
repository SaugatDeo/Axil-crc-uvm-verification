#include <stdint.h>

static uint8_t buf[512];
static int     n;

static uint32_t crc32_buf(const uint8_t *p, int len)
{
    uint32_t c = 0xFFFFFFFFu;
    while (len--) {
        c ^= *p++;
        for (int i = 0; i < 8; i++)
            c = (c & 1u) ? (c >> 1) ^ 0xEDB88320u : (c >> 1);
    }
    return ~c;
}

void ref_clear(void)
{
    n = 0;
}

void ref_byte(uint8_t b)
{
    if (n < (int)sizeof buf)
        buf[n] = b;
    n++;
}

uint8_t ref_result(void)
{
    int      total = n;
    int      len   = total > 4 ? total - 4 : 0;
    int      ok    = total >= 5 && total <= 64;
    uint32_t rx    = 0;

    if (len > 127)
        len = 127;
    if (ok) {
        for (int i = 0; i < 4; i++)
            rx |= (uint32_t)buf[total - 4 + i] << (8 * i);
        ok = (crc32_buf(buf, total - 4) == rx);
    }
    n = 0;
    return (uint8_t)((ok << 7) | len);
}