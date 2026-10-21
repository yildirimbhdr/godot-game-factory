---
id: 0007
title: Parallel genart runs lost a ledger entry
area: workflow
severity: major
status: encoded
---

**What happened:** two `genart.py` calls ran in parallel; both read the ledger, both appended, the last write won, so one paid image was not counted against the credit limit.
**Rule:** the budget check and the reservation of the cost happen inside a file lock (`ledger_lock`) before the API call; a refused API call releases the reservation. Any shared counter that guards money needs a lock.
**Applies to:** `scripts/genart.py`, any future script that spends credits.
**Encoded in:** `scripts/genart.py` (`ledger_lock` reserves the cost before the API call)
