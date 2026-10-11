# axil_crc test plan

| ID  | Feature | Scenario | Check | Coverage item |
|-----|---------|----------|-------|---------------|
| F1  | Reset | Reset at start and mid-traffic | Registers 0, FIFO empty, tready low | cp_reset_phase |
| F2  | Enable | Send packet with enable=0, then enable | tready low until enabled, no push while disabled | cp_enable |
| F3  | CRC good | Random payload 1..59 bytes, correct CRC | RESULT crc_ok=1, len=payload | cp_len, cp_crc_ok |
| F4  | CRC bad | Flip 1 bit in payload or CRC | crc_ok=0, crc_err_seen=1 | cp_crc_ok, cp_err_pos |
| F5  | Length limits | Total 4, 5, 64, 65 bytes | Total 5..64 valid, others crc_ok=0 | cp_len bins (edges) |
| F6  | FIFO | Fill to 8 without reading, read all | full flag, tready low when full, order kept | cp_fifo_level, cp_full |
| F7  | Back-pressure | Packet sent while FIFO full | Stream stalls, no data lost or duplicated | cx_full_x_tvalid |
| F8  | Stream gaps | Random tvalid gaps inside packet | Same result as no-gap packet | cp_gap |
| F9  | RESULT pop | Read RESULT when empty | Returns 0, no underflow | cp_empty_read |
| F10 | IRQ | irq_en 0/1, push, W1C clear | irq = IRQ_STAT & IRQ_EN | cx_irq_en_x_stat |
| F11 | IRQ race | Push and W1C in the same cycle | Push wins, stat stays 1 | cp_push_w1c_same |
| F12 | Soft reset | CTRL[1] with FIFO non-empty | FIFO, IRQ_STAT, crc_err_seen cleared | cp_soft_reset |
| F13 | Bus errors | Write to RO or unmapped, read unmapped | SLVERR, no side effect | cp_addr, cp_resp |
| F14 | Bus handshake | Random bready/rready delay, back-to-back access | No dropped or doubled response | cp_ready_delay |
| F15 | Packet back-to-back | tlast followed by tvalid next cycle | Independent CRC per packet | cp_b2b |

## Coverage goals
- Functional coverage: 100% of bins above, with any exclusions explained
- Code coverage: line and branch above 95%, holes explained

## Not verified (known limitations)
- wstrb is ignored by design
- Multiple outstanding AXI-Lite transactions are not supported