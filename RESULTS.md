# LA28 Olympics — MIP Results

Solver: HiGHS 1.11.0 via amplpy (AMPL 20250901).
Data source: `main.dat` (and task-specific `task1.dat`, `task2.dat`).
Run with: `source .venv/bin/activate && python run_all.py`.

| Task | Model | Data | Objective (thousand $) |
|---|---|---|---|
| 1 | `task1.mod` | `task1.dat` | **1,800** fixed cost |
| 2 | `task2.mod` | `task2.dat` | **2,850** fixed cost |
| 3 | `task3.mod` | `main.dat`  | **270** net cost |
| 4 | `task4.mod` | `main.dat`  | **100** net cost |

---

## Task 1 — Venue Selection & Sport Assignment

**Minimum total fixed cost: $1,800,000** (5 venues opened)

| Venue | Cost ($K) | Sports assigned |
|---|---|---|
| V2 Rose Bowl | 500 | S1 Athletics, S4 Soccer, S11 Cycling, S14 Equestrian |
| V4 Dignity Health | 400 | S5 Basketball, S9 Tennis |
| V5 UCLA | 350 | S2 Swimming, S3 Gymnastics, S10 Volleyball |
| V7 Long Beach | 300 | S6 Boxing, S7 Wrestling, S15 Sailing |
| V8 Pomona | 250 | S8 Weightlifting, S12 Archery, S13 Shooting |

Every sport is assigned to exactly one eligible venue. V2 alone absorbs the
four Rose-Bowl-eligible sports (Athletics, Soccer, Cycling, Equestrian) and
V5/V7/V8 each cluster three sports — there is no week constraint, so the
solver packs sports into the cheapest eligible venues with no upper bound
beyond eligibility.

---

## Task 2 — Multi-Week Scheduling

**Minimum total fixed cost: $2,850,000** (8 venues) — **+$1,050K (+58%) vs. Task 1**

| Venue (κᵢ) | Cost | W1 | W2 | W3 |
|---|---|---|---|---|
| V1 SoFi (3) | 500 | S11 Cycling | S4 Soccer | S4 Soccer |
| V2 Rose Bowl (3) | 500 | S1 Athletics | S1 Athletics | S14 Equestrian |
| V3 Crypto (3) | 400 | S5 Basketball | S10 Volleyball | S3 Gymnastics |
| V6 USC (2) | 350 | S2 Swimming | S7 Wrestling | — |
| V7 Long Beach (2) | 300 | — | S15 Sailing | S6 Boxing |
| V8 Pomona (2) | 250 | S13 Shooting | — | S12 Archery |
| V9 Forum (2) | 300 | — | S3 Gymnastics | S5 Basketball |
| V10 Dignity South (2) | 250 | — | S8 Weightlifting | S9 Tennis |

**What changed vs. Task 1 and why:**

- Five venues cannot absorb the 19 required sport-weeks because each venue
  caps at κᵢ ≤ 3 sport-weeks and holds at most one sport per week. Required
  sessions total R = 2+1+2+2+2+1+1+1+1+1+1+1+1+1+1 = **19** — exactly the
  combined κ of the 8 opened venues (3+3+3+2+2+2+2+2 = 19). Every opened
  venue is fully saturated.
- The four multi-session sports (**S1 Athletics R=2, S3 Gymnastics R=2,
  S4 Soccer R=2, S5 Basketball R=2**) drive the extra openings. The solver
  uses two strategies:
  - **Same venue, different weeks** — S1 at V2 (W1, W2), S4 at V1 (W2, W3).
    Cheaper when the venue is already open.
  - **Two different venues** — S3 at V3 (W3) + V9 (W2), S5 at V3 (W1) +
    V9 (W3). Forced when eligibility is narrow (only V3, V5, V9 can host
    gymnastics; only V3, V4, V9 can host basketball).
- Task 1's V4, V5 are dropped. V1, V3, V6, V9, V10 are added. V2, V7, V8
  are retained. The solver now values high-κ venues (V1, V2, V3 with κ=3)
  plus a ring of κ=2 venues to fan out multi-session sports.

---

## Task 3 — Ticket Sales

**Minimum total cost: $270,000 net** (fixed $2,850K − revenue $2,580K) —
**$2,580K improvement over Task 2**

**Facilities used:** Identical set to Task 2 (V1, V2, V3, V6, V7, V8, V9,
V10). The minor assignment reshuffles (V10 hosts S9 Tennis instead of S8;
V8 hosts S8 Weightlifting instead of S12; S12 moves to V10) are revenue
neutral — both venue pairs have capacity C=8 and these swaps don't change
what the solver can sell.

**Tickets sold per event (thousands):**

| Sport | Demand/session × R | Tickets sold (T3) | Capacity-limited? |
|---|---|---|---|
| S1 Athletics | 30 × 2 = 60 | **60** | no |
| S2 Swimming | 15 × 1 = 15 | **10** | yes — V6 cap 10 |
| S3 Gymnastics | 9 × 2 = 18 | **18** | no |
| S4 Soccer | 32 × 2 = 64 | **64** | no |
| S5 Basketball | 9 × 2 = 18 | **18** | no |
| S6 Boxing | 8 | **8** | no |
| S7 Wrestling | 7 | **7** | no |
| S8 Weightlifting | 5 | **5** | no |
| S9 Tennis | 10 | **8** | yes — V10 cap 8 |
| S10 Volleyball | 12 | **12** | no |
| S11 Cycling | 20 | **20** | no |
| S12 Archery | 6 | **6** | no |
| S13 Shooting | 4 | **4** | no |
| S14 Equestrian | 8 | **8** | no |
| S15 Sailing | 10 | **10** | no |
| **Total** | **275** | **258** | |

**How this differs from Tasks 1 & 2:** Tasks 1 and 2 didn't model ticket
revenue, so there was no cost pressure to put high-demand sports at
high-capacity venues. The *implied* sales — if Task 2's schedule were
priced — work out to the same 258K tickets, because Task 3 chose the
same venue set and any capacity-binding pairings (Swimming at V6, Tennis
at V10) are inherited from eligibility and capacity, not solver choice.
The key insight: **the solution is already revenue-optimal given the
venue opening decisions in Task 2**, because the venues with the biggest
capacity (V1 SoFi C=70, V2 Rose Bowl C=90) naturally attract the biggest-
demand sports (Soccer D=32, Athletics D=30, Cycling D=20) through
eligibility. Two events lose tickets to capacity: Swimming (5K lost at
USC) and Tennis (2K lost at Dignity South).

---

## Task 4 — Bus Networks

**Minimum total cost: $100,000 net** — **$170K improvement over Task 3**

Cost breakdown: $2,850K fixed − $2,580K base ticket revenue
− $250K bus uplift revenue + $80K bus setup = **$100K**.

**Bus lines opened (4 two-venue networks, each $20K):**

| Pair | Rationale |
|---|---|
| **V1 SoFi ↔ V3 Crypto** | V1 active all 3 weeks with high-demand events (S1 W1/W2, S11 W3); 10% of attendance flows to V3 → +11K extras |
| **V2 Rose Bowl ↔ V6 USC** | V2 hosts S4 Soccer (32K) in W1 and W3, coinciding with V6 active (S2 W1, S7 W3) → +8K extras |
| **V7 Long Beach ↔ V8 Pomona** | Both active W1 and W3 → +3K extras |
| **V9 Forum ↔ V10 Dignity South** | Both active W1 and W2 → +4K extras |

**Facilities used:** Same 8 venues as Task 3. Bus option doesn't change
which sites to open, only how they cooperate.

**Scheduling changes vs. Task 3:** The solver re-timed week assignments
to maximize co-active bus pairs:

- S1 Athletics moved from V2→V1 (W1, W2), putting two 30K-demand sessions
  at V1 to feed the V1↔V3 line.
- S11 Cycling moved to V1 (W3), keeping V1 active every week.
- S4 Soccer now at V2 in W1 and W3, feeding V2↔V6 in both V6-active weeks.
- V9 and V10 re-aligned so both are active in W1 and W2 together.

**Total tickets sold:** 258K base + 25K bus uplift = **283K effective**.

| Bus arc | W1 | W2 | W3 | Total |
|---|---|---|---|---|
| V1→V3 | 3.0 | 3.0 | 2.0 | 8.0 |
| V3→V1 | 1.2 | 0.9 | 0.9 | 3.0 |
| V2→V6 | 3.2 | — | 3.2 | 6.4 |
| V6→V2 | 1.0 | — | 0.7 | 1.7 |
| V7→V8 | 0.8 | — | 1.0 | 1.8 |
| V8→V7 | 0.4 | — | 0.5 | 0.9 |
| V9→V10 | 0.9 | 0.9 | — | 1.8 |
| V10→V9 | 0.8 | 0.6 | — | 1.4 |
| **Total uplift** | | | | **25.0** |

**Key insight:** Every bus line's payoff is
`0.10 × (origin attendance) × (weeks both venues active)`.
V4, V5, and others are outside any network because they're either not
co-active enough weeks or not paired with a high-attendance partner.
Each venue is in at most one bus network, as required.

---

## Cross-Task Summary

| Metric | Task 1 | Task 2 | Task 3 | Task 4 |
|---|---|---|---|---|
| Venues opened | 5 | 8 | 8 | 8 |
| Fixed cost ($K) | 1,800 | 2,850 | 2,850 | 2,850 |
| Base ticket revenue ($K) | — | — | 2,580 | 2,580 |
| Bus uplift revenue ($K) | — | — | — | 250 |
| Bus setup cost ($K) | — | — | — | 80 |
| **Net objective ($K)** | **1,800** | **2,850** | **270** | **100** |
| Total tickets (thousands) | — | — | 258 | 283 |
