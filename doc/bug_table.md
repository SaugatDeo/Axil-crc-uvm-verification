# Bug injection (seed 1)

| # | Injected bug | rand_test | reg_test | fifo_test | race_test | long_test | ready_test | enable_test | Result |
|---|---|---|---|---|---|---|---|---|---|
| 1 | CRC residue constant wrong | uvm | uvm | uvm | uvm | uvm | uvm | uvm | caught |
| 2 | Max length off by one, accepts 65 bytes | uvm | clean | clean | clean | uvm | clean | clean | caught |
| 3 | FIFO reports full one entry early | uvm | clean | uvm | clean | clean | clean | clean | caught |
| 4 | tready ignores enable | sva | sva | sva | sva | sva | sva | sva+uvm | caught |
| 5 | crc_err_seen never set | clean | uvm | clean | clean | clean | clean | clean | caught |
| 6 | RESULT read does not pop the FIFO | uvm | clean | uvm | uvm | uvm | uvm | clean | caught |
| 7 | Soft reset leaves irq_stat set | clean | sva+uvm | clean | clean | clean | clean | clean | caught |
| 8 | Write to read-only register returns OKAY | clean | uvm | clean | clean | clean | uvm | clean | caught |
| 9 | IRQ clear beats a push in the same cycle | clean | clean | clean | sva | clean | clean | clean | caught |

Caught 9 of 9 valid bugs.
