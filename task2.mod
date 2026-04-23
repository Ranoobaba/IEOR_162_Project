# =========================================================
# Task 2: Multi-Week Scheduling
# Goal: Extend Task 1 so each sport j gets R_j venue slots
# (all in the same week is handled implicitly: a sport may
# be scheduled across multiple venues, one slot per venue
# per week). A venue with capacity kappa_i can be used in
# weeks 1..kappa_i, and hosts at most one sport per week.
#
# What's new vs. Task 1:
#   + Set T (weeks of the Games)
#   + Params kappa[V] (sport-week cap), R[S] (required sessions)
#   + Variable z[V,S,T] (scheduled in week t?)
#   + Constraints: RequiredSessions, OneSportPerVenueWeek,
#                  VenueWeekLimit, ScheduleOnlyIfAssigned
#   - Objective unchanged (still just fixed venue cost)
#   - AssignEachSport becomes implied by RequiredSessions
#     (kept here only via y-linking constraints)
# =========================================================

set V;                       # venues
set S;                       # sports
set T;                       # weeks of the Games (1..max kappa_i)

param c{V} >= 0;             # c_i: fixed utilization cost of venue i
param kappa{V} >= 0;         # kappa_i: max number of sport-weeks venue i can host
param R{S} >= 0;             # R_j: required number of venue slots for sport j (Table 2)
param a{V,S} binary;         # a_ij: eligibility matrix (Table 3)

var x{V} binary;             # x_i = 1 if venue i is opened
var y{V,S} binary;           # y_ij = 1 if sport j is assigned to venue i
var z{V,S,T} binary;         # z_ijt = 1 if sport j is held at venue i in week t

# Objective: still minimize fixed cost of opened venues
minimize TotalCost:
    sum{i in V} c[i] * x[i];

# ---------- Task 1 constraints carry over ----------

# Each sport must be assigned to at least one venue (covered via z below),
# but we keep the y-assignment as the "is this sport ever at this venue" flag
subject to OpenLink{i in V, j in S}:
    y[i,j] <= x[i];          # can only assign to opened venues

subject to Eligibility{i in V, j in S}:
    y[i,j] <= a[i,j];        # respect the eligibility matrix

# ---------- Task 2 constraints ----------

# Sport j must be scheduled in exactly R_j distinct (venue, week) slots
subject to RequiredSessions{j in S}:
    sum{i in V, t in T} z[i,j,t] = R[j];

# A venue can host at most one sport in any given week
subject to OneSportPerVenueWeek{i in V, t in T}:
    sum{j in S} z[i,j,t] <= 1;

# Total scheduled sport-weeks at venue i cannot exceed its limit kappa_i
subject to VenueWeekLimit{i in V}:
    sum{j in S, t in T} z[i,j,t] <= kappa[i];

# A sport can only be scheduled at a venue where it has been assigned
subject to ScheduleOnlyIfAssigned{i in V, j in S, t in T}:
    z[i,j,t] <= y[i,j];
