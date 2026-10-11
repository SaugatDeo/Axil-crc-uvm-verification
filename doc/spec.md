# axil_crc spec

Block: AXI4-Lite slave + AXI-Stream sink. Receives packets, checks CRC-32, logs result.

## Stream input
- 8-bit tdata, tvalid, tready, tlast
- Packet = payload bytes + 4 CRC bytes (LSB first). tlast on final CRC byte.
- Min packet 5 bytes (1 payload + 4 CRC), max 64
- CRC-32 IEEE 802.3, poly 0x04C11DB7, reflected, init 0xFFFFFFFF, final XOR 0xFFFFFFFF
- tready low only while result FIFO is full (back-pressure)

## Result FIFO
- Depth 8, entry = {crc_ok[0], len[6:0]} (len = payload bytes)
- Pushed on tlast; if FIFO full, the packet is not accepted (tready low)

## Registers (32-bit, word aligned)
| Addr | Name | Access | Bits |
|------|------|--------|------|
| 0x00 | CTRL | RW | [0] enable, [1] soft_reset (self-clearing) |
| 0x04 | STATUS | RO | [0] fifo_empty, [1] fifo_full, [2] crc_err_seen |
| 0x08 | RESULT | RO | [7] crc_ok, [6:0] len; read pops FIFO; reads 0 if empty |
| 0x0C | IRQ_EN | RW | [0] irq on fifo not empty |
| 0x10 | IRQ_STAT | RW1C | [0] fifo_not_empty (set on push, write 1 to clear) |

## Interrupt
- irq = |(IRQ_STAT & IRQ_EN)

## Reset
- Active-low rstn, soft_reset clears FIFO, IRQ_STAT and crc_err_seen

## v2 clarifications
- Reset: synchronous, all registers 0 (enable=0 until CTRL written)
- tready = enable & !fifo_full
- Packet length: total bytes 5..64 valid; otherwise pushed with crc_ok=0
- len field = total-4, 0 if total<=4, saturates at 127
- soft_reset clears CRC state, byte count, FIFO, IRQ_STAT, crc_err_seen
- RESULT read pops FIFO when read address is accepted; empty reads 0, no pop
- IRQ_STAT: set on push (wins over W1C), cleared by W1C or soft_reset
- AXI-Lite: AW and W accepted together, one outstanding write, one outstanding read
- Write to STATUS/RESULT or any unmapped address: SLVERR, no effect
- Read of unmapped address: SLVERR, data 0
- wstrb ignored, address bits [1:0] ignored