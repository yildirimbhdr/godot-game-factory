---
name: lessons-learned
description: Record a mistake as a lesson and make it impossible to repeat by encoding it in a template, script, test or skill. Use whenever the user reports a defect, a test is flaky, or something had to be redone.
---

# Lessons learned

A lesson is finished only when something enforces it. Writing a rule nobody checks does not count.

1. Read `lessons/README.md` for the file format. Number the next file `NNNN-short-slug.md`.
2. Fill in: what happened (what the user saw), root cause (why the process allowed it), the one-sentence rule.
3. **Encode** the rule: a template change, a check in `scripts/`, a step in `playtest/smoke.json`, or a line in a skill. Name it in `Encoded in:` and set `status: encoded`.
4. If it cannot be encoded yet, leave `status: open` and say so to the user.
5. At the start of every new game read all of `lessons/`; a repeated mistake means the previous lesson was not really encoded, so fix that.

Never include secrets, Team IDs or personal data in a lesson: this repository is public.
