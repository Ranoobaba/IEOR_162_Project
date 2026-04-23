# =========================================================
# Task 3: Ticket Sales
# Goal: Offset venue cost by $10 (thousand) per thousand
# tickets sold, where tickets sold per session is capped by
# the minimum of sport demand D_j and venue capacity C_i.
#
# What's new vs. Task 2:
#   + Params C[V] (capacity), D[S] (per-session demand),
#            M (Big-M for linking sold to schedule)
#   + Variable sold[V,S,T] (tickets sold, thousands)
#   + Objective gains -10 * sum(sold) revenue term
#   + Constraints: SoldBoundDemand, SoldBoundCapacity,
#                  SoldOnlyIfScheduled
# =========================================================

set V;                       # venues
set S;                       # sports
set T;                       # weeks

param c{V} >= 0;             # c_i: fixed cost of venue i
param C{V} >= 0;             # C_i: seating capacity of venue i (thousand seats)
param kappa{V} >= 0;         # kappa_i: max sport-weeks at venue i
param D{S} >= 0;             # D_j: peak ticket demand per session for sport j
param R{S} >= 0;             # R_j: required sessions for sport j
param a{V,S} binary;         # a_ij: eligibility

param M >= 0 default 1000;   # Big-M for linking sold[] to the schedule variable z

var x{V} binary;             # x_i = 1 if venue is opened
var y{V,S} binary;           # y_ij = 1 if sport j assigned to venue i
var z{V,S,T} binary;         # z_ijt = 1 if sport j held at venue i in week t
var sold{V,S,T} >= 0;        # tickets sold (thousands) for sport j at venue i in week t

# Objective: fixed cost minus ticket revenue ($10 per thousand tickets)
minimize TotalCost:
    sum{i in V} c[i] * x[i]
    - 10 * sum{i in V, j in S, t in T} sold[i,j,t];

# ---------- Task 1 / 2 constraints ----------
subject to AssignEachSport{j in S}:
    sum{i in V} y[i,j] = 1;          # every sport assigned somewhere

subject to OpenLink{i in V, j in S}:
    y[i,j] <= x[i];                  # only open venues host sports

subject to Eligibility{i in V, j in S}:
    y[i,j] <= a[i,j];                # only eligible pairings

subject to RequiredSessions{j in S}:
    sum{i in V, t in T} z[i,j,t] = R[j];   # cover required sessions

subject to OneSportPerVenueWeek{i in V, t in T}:
    sum{j in S} z[i,j,t] <= 1;       # one sport per venue per week

subject to VenueWeekLimit{i in V}:
    sum{j in S, t in T} z[i,j,t] <= kappa[i];   # within venue's sport-week cap

subject to ScheduleOnlyIfAssigned{i in V, j in S, t in T}:
    z[i,j,t] <= y[i,j];              # schedule only where assigned

# ---------- Task 3 constraints ----------

# Tickets sold cannot exceed the sport's per-session demand
subject to SoldBoundDemand{i in V, j in S, t in T}:
    sold[i,j,t] <= D[j];

# Tickets sold cannot exceed the venue's seating capacity
subject to SoldBoundCapacity{i in V, j in S, t in T}:
    sold[i,j,t] <= C[i];

# Tickets are only sold if that sport is actually scheduled there that week
subject to SoldOnlyIfScheduled{i in V, j in S, t in T}:
    sold[i,j,t] <= M * z[i,j,t];
