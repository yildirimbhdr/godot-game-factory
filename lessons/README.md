# Lessons

Every mistake that reaches the user becomes a lesson, so it cannot happen twice.
One file per lesson: `NNNN-short-slug.md`.

```markdown
---
id: 0001
title: <what went wrong, in one line>
area: ui | audio | assets | juice | export | testing | workflow
severity: blocker | major | minor
status: open | encoded        # encoded = a skill rule, template, test or hook now prevents it
---

**What happened:** facts, what the user saw.
**Root cause:** why the process allowed it.
**Rule:** the one-sentence rule that prevents it.
**Encoded in:** path to the skill/template/hook/test that enforces the rule (empty while status is open).
```

A lesson is only done when it is `encoded`. A written rule nobody enforces does not count.
