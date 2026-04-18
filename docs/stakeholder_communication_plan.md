# Stakeholder Communication Plan

**Project:** Enterprise Sales Intelligence Platform
**Author:** Devanshi
**Version:** 1.0 | **Last updated:** April 2026
**Status:** Approved

---

## Purpose

This document defines who receives what information, how often, in what
format, and who is responsible for sending it. A project without a
communication plan creates surprises — stakeholders who feel uninformed
disengage, and stakeholders who feel overwhelmed stop reading.

> **Rule:** No stakeholder should ever be surprised by project status.
> If something is blocked, delayed, or changed — communicate it the same day.

---

## Stakeholder Register

| Name | Role | Interest level | Influence level | Communication preference |
|---|---|---|---|---|
| Priya Sharma | CFO — Executive Sponsor | High | High | Short summaries, no jargon, outcomes-focused |
| Sarah Chen | Regional Sales Manager — Primary User | High | Medium | Visual, practical, "what does this mean for me" |
| Marcus Obi | Finance Business Analyst — Primary User | High | Medium | Detail-oriented, numbers, audit trail |
| Devanshi | Data Engineer + Product Owner | High | High | Internal — self-communication and GitHub tracking |
| IT / DBA | Infrastructure and access | Medium | Medium | Technical, written, asynchronous |

---

## RACI Matrix

**R** = Responsible (does the work)
**A** = Accountable (owns the outcome)
**C** = Consulted (input required before action)
**I** = Informed (kept updated, no action needed)

| Activity | Devanshi (PO/DE) | Priya (CFO) | Sarah (Sales) | Marcus (Finance) | IT / DBA |
|---|---|---|---|---|---|
| Project initiation and BRD | R / A | C | C | C | I |
| Sprint planning | R / A | I | I | I | — |
| Technical build (Bronze–Gold) | R / A | I | I | I | C |
| KPI definition approval | R | A | C | C | — |
| Dashboard design sign-off | R | C | A | C | — |
| Data quality incident response | R / A | I | I | C | C |
| Sprint review presentation | R / A | I | C | C | — |
| Go-live announcement | R | A | I | I | I |
| Post-launch bug fixes | R / A | I | I | C | C |

---

## Communication Schedule

### Bi-weekly Executive Update → Priya Sharma (CFO)

| Field | Detail |
|---|---|
| **Frequency** | Every 2 weeks — end of each sprint |
| **Format** | 5-bullet email — no attachments, no technical detail |
| **Owner** | Devanshi |
| **Channel** | Email |
| **Purpose** | Keep the executive sponsor informed of milestone progress, budget confidence, and any decisions needed at her level |

**Template:**

```
Subject: Enterprise Sales Intelligence Platform — Sprint [N] Update

Hi Priya,

Quick update on the data warehouse project:

✅ Completed this sprint:
   [1–2 lines — what was shipped, in business terms]

🔄 In progress:
   [What is being built right now]

⚠️ Decisions needed:
   [Any blocker that needs executive input — leave blank if none]

📅 Next milestone:
   [What the next sprint delivers and when]

📊 Overall status: ON TRACK / AT RISK / DELAYED
   [One sentence if anything other than ON TRACK]

Dashboard preview available on request.

Devanshi
```

---

### Per-Sprint Dashboard Preview → Sarah Chen (Sales Manager)

| Field | Detail |
|---|---|
| **Frequency** | End of every sprint (every 2 weeks) |
| **Format** | Screenshot of latest dashboard page + 3 bullet points |
| **Owner** | Devanshi |
| **Channel** | Email or Slack message |
| **Purpose** | Show Sarah what has been built, validate it matches her needs, catch misalignments early |

**Template:**

```
Hi Sarah,

Sprint [N] is done — here's what's new in the dashboard:

[Screenshot of dashboard page]

What's now available:
• [KPI or feature 1 — written in Sarah's language, not technical]
• [KPI or feature 2]
• [KPI or feature 3]

Does this match what you need? Any changes before we move to the next page?

Devanshi
```

---

### Per-Sprint Data Model Review → Marcus Obi (Finance Analyst)

| Field | Detail |
|---|---|
| **Frequency** | End of every sprint |
| **Format** | Table review email — column names, formulas, data rules |
| **Owner** | Devanshi |
| **Channel** | Email |
| **Purpose** | Ensure every KPI formula and data rule aligns with what Finance expects before it reaches Priya |

**Template:**

```
Hi Marcus,

Sprint [N] data model update for your review:

Tables updated this sprint:
• [table name] — [what changed]
• [table name] — [what changed]

KPI formulas to confirm:
• [KPI name]: [formula] — does this match your expectation?
• [KPI name]: [formula]

Known data quality items:
• [Any DQ issue found this sprint and how it was handled]

Anything to flag before this goes into the dashboard?

Devanshi
```

---

### Weekly Internal Status → GitHub Projects Board

| Field | Detail |
|---|---|
| **Frequency** | Every Friday |
| **Format** | GitHub Projects board updated + commit pushed |
| **Owner** | Devanshi |
| **Channel** | GitHub |
| **Purpose** | Maintain a public, real-time record of project status visible to anyone viewing the repo |

**Checklist (every Friday):**
- [ ] All completed tasks moved to Done column on the board
- [ ] All blocked items tagged with `blocked` label and a comment explaining why
- [ ] At least one commit pushed to the repo this week
- [ ] README updated if anything major shipped

---

### Immediate Alert — Blockers and Incidents

| Field | Detail |
|---|---|
| **Frequency** | Same day as the blocker or incident is discovered |
| **Format** | Short direct message or email |
| **Owner** | Devanshi |
| **Audience** | Relevant stakeholder only (not a group email unless it affects everyone) |
| **Purpose** | No stakeholder learns about a problem from someone else first |

**Examples that trigger an immediate alert:**
- A DQ check fails and data in the dashboard may be incorrect
- A sprint story will miss the sprint — carry-forward expected
- A new requirement emerges that changes scope
- A technical dependency (SQL Server, dbt install) is blocked

---

## Communication Calendar Summary

| Communication | Audience | Frequency | Owner | Format |
|---|---|---|---|---|
| Executive sprint update | Priya | Bi-weekly | Devanshi | 5-bullet email |
| Dashboard preview | Sarah | Per sprint | Devanshi | Screenshot + bullets |
| Data model review | Marcus | Per sprint | Devanshi | Table review email |
| GitHub board update | Anyone with repo access | Weekly (Friday) | Devanshi | Board + commit |
| Blocker / incident alert | Relevant stakeholder | Same day | Devanshi | Direct message |
| Sprint review notes | All stakeholders | Per sprint | Devanshi | Markdown in /docs |
| Go-live announcement | All stakeholders | Once | Devanshi | Email + LinkedIn |

---

## Escalation Path

If a decision is needed that cannot wait for the scheduled communication:

1. **Level 1 — Data or model question:** Resolve with Marcus directly
2. **Level 2 — Scope or requirement change:** Raise with Sarah and Marcus together
3. **Level 3 — Budget, timeline, or strategic decision:** Escalate to Priya immediately

---

## Change Log

| Version | Date | Change | Author |
|---|---|---|---|
| 1.0 | April 2026 | Initial plan — 5 stakeholders, 5 communication channels | Devanshi |

---

*Part of the Enterprise Sales Intelligence Platform · github.com/Devanshi-20*
