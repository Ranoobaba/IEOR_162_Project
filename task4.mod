# =========================================================
# Task 4: Bus Networks
# Goal: Optionally connect venues by bus at $20 (thousand)
# per link. If venues i and k are connected and both host
# events in week t, 10% of i's attendees also buy tickets
# at k (and vice versa). Each venue can belong to at most
# one network. (The 3-venue 7%/7% case from the PDF is
# approximated via pairwise links; extend if a true 3-venue
# network variable is required.)
#
# What's new vs. Task 3:
#   + Variables b[V,V] (bus link), active[V,T] (venue used
#                that week?), extra[V,V,T] (uplift tickets)
#   + Objective gains -10 * sum(extra) (added revenue)
#                 and +20 * sum(b) over unordered pairs
#                     (bus network setup cost)
#   + Constraints defining active:
#       DefineActiveUpper, DefineActiveLower
#   + Bus-network constraints:
#       NoSelfBus, BusSymmetry, OneBusNetworkPerVenue,
#       ExtraOnlyIfConnected, ExtraOnlyIfOriginActive,
#       ExtraOnlyIfDestActive, ExtraTicketCap (10% rule)
# =========================================================

set V ordered;               # candidate venues (V1..V10) — ordered so ord() is usable
set S;                       # Olympic sports (S1..S15)
set T;                       # weeks of the Games

param c{V} >= 0;             # c_i: fixed utilization cost of venue i
param C{V} >= 0;             # C_i: seating capacity of venue i
param kappa{V} >= 0;         # kappa_i: max sport-weeks venue i can host
param D{S} >= 0;             # D_j: per-session demand for sport j
param R{S} >= 0;             # R_j: required session slots for sport j
param a{V,S} binary;         # a_ij: eligibility matrix (Table 3)

# Big-M constant used to linearize "only if" logic
param M >= 0 default 1000;

# ---------- Task 1 / 2 / 3 variables ----------
var x{V} binary;             # x_i = 1 if venue i is opened
var y{V,S} binary;           # y_ij = 1 if sport j is assigned to venue i
var z{V,S,T} binary;         # z_ijt = 1 if sport j is scheduled at venue i in week t
var sold{V,S,T} >= 0;        # base tickets sold (thousands) for (i,j,t)

# ---------- Task 4 variables ----------
var b{V,V} binary;           # b_ik = 1 if venues i and k are bus-connected
var active{V,T} binary;      # active_it = 1 if venue i hosts any sport in week t
var extra{V,V,T} >= 0;       # extra tickets at venue k induced by bus from i in week t

# ---------- Objective ----------
# fixed venue cost  -  ticket revenue ($10/k)  -  bus-induced revenue ($10/k)
# +  bus network setup cost ($20/k per link, counted once per unordered pair)
minimize TotalCost:
    sum{i in V} c[i] * x[i]
    - 10 * sum{i in V, j in S, t in T} sold[i,j,t]
    - 10 * sum{i in V, k in V, t in T: i <> k} extra[i,k,t]
    + 20 * sum{i in V, k in V: ord(i) < ord(k)} b[i,k];

# =========================================================
# Task 1: Assignment
# =========================================================

# Each sport must be assigned to exactly one venue
subject to AssignEachSport{j in S}:
    sum{i in V} y[i,j] = 1;

# A sport can only be assigned to an opened venue
subject to OpenLink{i in V, j in S}:
    y[i,j] <= x[i];

# A sport can only be assigned where it is eligible (a_ij = 1)
subject to Eligibility{i in V, j in S}:
    y[i,j] <= a[i,j];

# =========================================================
# Task 2: Multi-week scheduling
# =========================================================

# Sport j needs exactly R_j (venue, week) slots across the Games
subject to RequiredSessions{j in S}:
    sum{i in V, t in T} z[i,j,t] = R[j];

# At most one sport per venue per week
subject to OneSportPerVenueWeek{i in V, t in T}:
    sum{j in S} z[i,j,t] <= 1;

# Total sport-weeks at venue i cannot exceed kappa_i
subject to VenueWeekLimit{i in V}:
    sum{j in S, t in T} z[i,j,t] <= kappa[i];

# A sport can only be scheduled where it was assigned
subject to ScheduleOnlyIfAssigned{i in V, j in S, t in T}:
    z[i,j,t] <= y[i,j];

# "active" indicator: links the schedule z to the binary "is venue used this week"
subject to DefineActiveUpper{i in V, t in T}:
    sum{j in S} z[i,j,t] <= active[i,t];   # if any sport runs, active=1

subject to DefineActiveLower{i in V, t in T}:
    active[i,t] <= sum{j in S} z[i,j,t];   # if no sport runs, active=0

# =========================================================
# Task 3: Ticket sales
# =========================================================

# Sold tickets cannot exceed the sport's per-session demand
subject to SoldBoundDemand{i in V, j in S, t in T}:
    sold[i,j,t] <= D[j];

# Sold tickets cannot exceed the venue's seating capacity
subject to SoldBoundCapacity{i in V, j in S, t in T}:
    sold[i,j,t] <= C[i];

# Tickets are only sold when the event is actually scheduled
subject to SoldOnlyIfScheduled{i in V, j in S, t in T}:
    sold[i,j,t] <= M * z[i,j,t];

# =========================================================
# Task 4: Bus networks
# =========================================================

# A venue cannot have a bus link to itself
subject to NoSelfBus{i in V}:
    b[i,i] = 0;

# Symmetric connections: if i is connected to k, then k is connected to i
subject to BusSymmetry{i in V, k in V: ord(i) < ord(k)}:
    b[i,k] = b[k,i];

# Each venue can belong to at most one bus network (at most one partner here)
subject to OneBusNetworkPerVenue{i in V}:
    sum{k in V: k <> i} b[i,k] <= 1;

# Extra tickets can only appear on an existing bus link
subject to ExtraOnlyIfConnected{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * b[i,k];

# Origin venue must be active in week t for the uplift to apply
subject to ExtraOnlyIfOriginActive{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * active[i,t];

# Destination venue must also be active in week t
subject to ExtraOnlyIfDestActive{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * active[k,t];

# 10% uplift: extra at k is at most 10% of total attendance at origin i in week t
subject to ExtraTicketCap{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= 0.10 * sum{j in S} sold[i,j,t];
