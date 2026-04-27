# =========================================================
# Task 5: Sensitivity Analysis (parameterized Task 4)
# Goal: Re-run the full bus-network model under three
# scenarios to see how sensitive the optimal solution is.
#
# Scenarios (param-driven, no model changes needed):
#   A. baseline: p = 10, demand_factor = 1.0  (= Task 4)
#   B. lower profit: p = 5
#   C. higher profit: p = 15
#   D. overestimated demand: demand_factor = 0.9
#
# What's new vs. Task 4:
#   + Param p (profit per thousand tickets sold), default 10
#   + Param demand_factor (scales the D[j] cap), default 1.0
#   - The objective's "10 *" coefficient is replaced by p
#   - SoldBoundDemand uses demand_factor * D[j] instead of D[j]
# All other sets, params, variables, and constraints are
# identical to task4.mod.
# =========================================================

set V ordered;               # venues (ordered so ord() is valid)
set S;                       # sports
set T;                       # weeks

param c{V} >= 0;             # fixed utilization cost of venue i
param C{V} >= 0;             # seating capacity of venue i
param kappa{V} >= 0;         # max sport-weeks per venue
param D{S} >= 0;             # per-session ticket demand for sport j
param R{S} >= 0;             # required session slots for sport j
param a{V,S} binary;         # eligibility matrix

# ---------- Task 5 sensitivity parameters ----------
param p >= 0 default 10;                # profit per thousand tickets sold
param demand_factor >= 0 default 1.0;   # scale applied to D[j] (0.9 = overestimated by 10%)

param M >= 0 default 1000;   # Big-M for indicator linking

# ---------- Variables (same as Task 4) ----------
var x{V} binary;
var y{V,S} binary;
var z{V,S,T} binary;
var sold{V,S,T} >= 0;
var b{V,V} binary;
var active{V,T} binary;
var extra{V,V,T} >= 0;

# ---------- Objective: p replaces the hard-coded 10 ----------
minimize TotalCost:
    sum{i in V} c[i] * x[i]
    - p * sum{i in V, j in S, t in T} sold[i,j,t]
    - p * sum{i in V, k in V, t in T: i <> k} extra[i,k,t]
    + 20 * sum{i in V, k in V: ord(i) < ord(k)} b[i,k];

# =========================================================
# Assignment (Task 1)
# =========================================================
subject to AssignEachSport{j in S}:
    sum{i in V} y[i,j] = 1;

subject to OpenLink{i in V, j in S}:
    y[i,j] <= x[i];

subject to Eligibility{i in V, j in S}:
    y[i,j] <= a[i,j];

# =========================================================
# Multi-week scheduling (Task 2)
# =========================================================
subject to RequiredSessions{j in S}:
    sum{i in V, t in T} z[i,j,t] = R[j];

subject to OneSportPerVenueWeek{i in V, t in T}:
    sum{j in S} z[i,j,t] <= 1;

subject to VenueWeekLimit{i in V}:
    sum{j in S, t in T} z[i,j,t] <= kappa[i];

subject to ScheduleOnlyIfAssigned{i in V, j in S, t in T}:
    z[i,j,t] <= y[i,j];

subject to DefineActiveUpper{i in V, t in T}:
    sum{j in S} z[i,j,t] <= active[i,t];

subject to DefineActiveLower{i in V, t in T}:
    active[i,t] <= sum{j in S} z[i,j,t];

# =========================================================
# Ticket sales (Task 3) — demand scaled by demand_factor
# =========================================================
subject to SoldBoundDemand{i in V, j in S, t in T}:
    sold[i,j,t] <= demand_factor * D[j];

subject to SoldBoundCapacity{i in V, j in S, t in T}:
    sold[i,j,t] <= C[i];

subject to SoldOnlyIfScheduled{i in V, j in S, t in T}:
    sold[i,j,t] <= M * z[i,j,t];

# =========================================================
# Bus networks (Task 4)
# =========================================================
subject to NoSelfBus{i in V}:
    b[i,i] = 0;

subject to BusSymmetry{i in V, k in V: ord(i) < ord(k)}:
    b[i,k] = b[k,i];

subject to OneBusNetworkPerVenue{i in V}:
    sum{k in V: k <> i} b[i,k] <= 1;

subject to ExtraOnlyIfConnected{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * b[i,k];

subject to ExtraOnlyIfOriginActive{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * active[i,t];

subject to ExtraOnlyIfDestActive{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * active[k,t];

subject to ExtraTicketCap{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= 0.10 * sum{j in S} sold[i,j,t];
