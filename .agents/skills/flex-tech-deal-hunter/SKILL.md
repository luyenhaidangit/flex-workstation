---
name: flex-tech-deal-hunter
description: Finds and verifies legitimate deals for infrastructure and developer tools — free tiers, cloud/VPS credits, hosting and domain sales (11.11, Black Friday, Tet), student/startup programs, public coupons — then ranks them by true lifetime cost with sources and expiry dates. Use when the user asks to hunt deals, sales, free-tier programs, credits or discounts for VPS, cloud, hosting, domains, SaaS dev tools or AI API credits, shares a deal/program URL to evaluate, or when a scheduled run is checking upcoming sale events.
---

# Tech Deal Hunter

## Overview

Deal pages are marketing: the headline price is rarely the real cost. This skill finds infra/dev-tool offers, verifies each one at the primary source, and reports what it really costs over its lifetime, what the conditions are, and when it ends. Scope is infrastructure and developer tools only (VPS, cloud, hosting, domains, CI/CD, SaaS dev tools, AI API credits).

It reports; it never buys. The user decides and pays.

## When to Use

- "Find me a cheap VPS / free tier / hosting sale", "is this program worth it?" with a URL.
- Seasonal sale checks (11.11, 12.12, Black Friday, Cyber Monday, Tet) and a scheduled run.
- Comparing two or three offers for the same need.

Do not use for consumer hardware/software shopping, or to operate a production purchase or migration (hand that to the skill that owns the artifact).

## Core Process

1. **Pin the need.** Service type, minimum spec, region, budget, duration. If the user gave none, state a default assumption (e.g. 2 vCPU / 4 GB VPS, 12 months, Asia region) and proceed; ask only if the answer would change the shortlist.
2. **Sweep sources** with `WebSearch` in `extended` mode — prices and campaigns are time-sensitive, so do not answer from memory. Use the source groups in `references/sources.md`: official programs, seasonal sales, community boards, public coupons.
3. **Verify at the primary source.** Open the provider's own page. Record: offer, price, renewal price, expiry, eligibility (card, KYC, region, new customers only), hard limits (traffic, IO, CPU throttling), refund policy. Community posts are leads, not proof.
4. **Screen for red flags** using `references/red-flags.md`. Drop or clearly flag anything that fails.
5. **Rank by true cost**, not headline: `first-period price + renewals over the user's duration + fees (setup, IP, backup, domain renewal)`. A free tier is ranked by what it actually lets you run before it throttles or expires.
6. **Report** in the format below. Stamp the check date; anything not verified at source is labelled `unverified`.

## Legitimate Tricks Only

Recommend: student/startup/OSS programs, new-account credits used once on a real project, annual billing discounts, public coupon codes, region pricing, off-peak seasonal timing, committing to the right plan size.

Do not recommend or explain: creating multiple accounts to farm free tiers or credits, fake or borrowed KYC, virtual cards to dodge limits, or anything the provider's ToS forbids. These get accounts banned and can cost the user their data; say so in one line if asked, then offer a legitimate alternative.

## Output Format

```text
Deal check — <date> — need: <summary>

Top picks
| # | Provider / offer | Real cost (period) | Renewal | Ends | Conditions | Risk | Source |

Worth knowing
- <program or sale coming up, with date>

Dropped
- <offer> — <reason>

Unverified
- <lead> — <what is missing>
```

Keep it to the best 3–5 picks; a longer list is a search result, not advice.

## Scheduled Run Mode

When invoked by a scheduled task (no human question), run steps 2–5 for the default need above and report only what is actionable: deals ending within ~14 days, newly announced programs, and sale events starting within ~30 days (see the calendar in `references/sources.md`). If nothing notable, say "Không có deal đáng chú ý" in one line — no filler.

## Common Rationalizations

| Rationalization | Why it's wrong | Correct move |
| --- | --- | --- |
| "The banner says $1/month, report that." | Renewal is often 5–10x; the banner is the first-term price. | Always compute lifetime cost including renewal. |
| "A forum post says it works, good enough." | Posts go stale and some are affiliate bait. | Confirm on the provider's page; else mark `unverified`. |
| "Offer ends tonight, hurry." | Urgency is a sales tactic, not a reason to skip verification. | Verify first; report the deadline factually. |
| "Multiple accounts would double the free credit." | Violates ToS; risks ban and data loss. | Stick to the legitimate list above. |
| "Recall from memory is faster." | Prices and programs change monthly. | Search and cite sources every time. |

## Red Flags

- No source URL or check date on a claimed price.
- Report lists 10+ deals with no ranking or dropped list.
- A recommendation hides a renewal price, card/KYC requirement, or region limit.
- The skill proposes ToS-violating tricks, or tries to purchase or enter payment details.

## Verification

- [ ] Every pick has a primary-source link and the date it was checked.
- [ ] Renewal price and lifetime cost are stated for each pick.
- [ ] Expiry and eligibility conditions are listed.
- [ ] Red-flag screen was applied; dropped items are listed with reasons.
- [ ] Unverified leads are labelled, not mixed into top picks.
- [ ] No ToS-violating trick was recommended and nothing was purchased.
