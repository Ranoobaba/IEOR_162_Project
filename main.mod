set V;                 # venues
set S;                 # sports
set T;                 # weeks

param c{V} >= 0;       # fixed cost of venue
param C{V} >= 0;       # capacity of venue
param kappa{V} >= 0;   # max number of weeks / sports venue can host
param D{S} >= 0;       # demand per sport per session
param R{S} >= 0;       # required sessions
param a{V,S} binary;   # eligibility matrix

# Big-M
param M >= 0 default 1000;

# ---------- Task 1 / 2 / 3 variables ----------
var x{V} binary;             # 1 if venue is open
var y{V,S} binary;           # 1 if sport assigned to venue
var z{V,S,T} binary;         # 1 if sport j scheduled at venue i in week t
var sold{V,S,T} >= 0;        # base tickets sold

# ---------- Task 4 variables ----------
var b{V,V} binary;           # 1 if venues i and k are connected by bus
var active{V,T} binary;      # 1 if venue i hosts something in week t
var extra{V,V,T} >= 0;       # extra tickets from bus connection

# ---------- Objective ----------
minimize TotalCost:
    sum{i in V} c[i] * x[i]
    - 10 * sum{i in V, j in S, t in T} sold[i,j,t]
    - 10 * sum{i in V, k in V, t in T: i <> k} extra[i,k,t]
    + 20 * sum{i in V, k in V: ord(i) < ord(k)} b[i,k];

# =========================================================
# Task 1: Assignment
# =========================================================

subject to AssignEachSport{j in S}:
    sum{i in V} y[i,j] = 1;

subject to OpenLink{i in V, j in S}:
    y[i,j] <= x[i];

subject to Eligibility{i in V, j in S}:
    y[i,j] <= a[i,j];

# =========================================================
# Task 2: Multi-week scheduling
# =========================================================

subject to RequiredSessions{j in S}:
    sum{i in V, t in T} z[i,j,t] = R[j];

subject to OneSportPerVenueWeek{i in V, t in T}:
    sum{j in S} z[i,j,t] <= 1;

subject to VenueWeekLimit{i in V}:
    sum{j in S, t in T} z[i,j,t] <= kappa[i];

subject to ScheduleOnlyIfAssigned{i in V, j in S, t in T}:
    z[i,j,t] <= y[i,j];

# active indicator
subject to DefineActiveUpper{i in V, t in T}:
    sum{j in S} z[i,j,t] <= active[i,t];

subject to DefineActiveLower{i in V, t in T}:
    active[i,t] <= sum{j in S} z[i,j,t];

# =========================================================
# Task 3: Ticket sales
# =========================================================

subject to SoldBoundDemand{i in V, j in S, t in T}:
    sold[i,j,t] <= D[j];

subject to SoldBoundCapacity{i in V, j in S, t in T}:
    sold[i,j,t] <= C[i];

subject to SoldOnlyIfScheduled{i in V, j in S, t in T}:
    sold[i,j,t] <= M * z[i,j,t];

# =========================================================
# Task 4: Bus networks
# =========================================================

# no self-loop bus lines
subject to NoSelfBus{i in V}:
    b[i,i] = 0;

# symmetry
subject to BusSymmetry{i in V, k in V: ord(i) < ord(k)}:
    b[i,k] = b[k,i];

# each venue in at most one network
subject to OneBusNetworkPerVenue{i in V}:
    sum{k in V: k <> i} b[i,k] <= 1;

# extra tickets only if connected
subject to ExtraOnlyIfConnected{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * b[i,k];

# extra tickets only if both venues active that week
subject to ExtraOnlyIfOriginActive{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * active[i,t];

subject to ExtraOnlyIfDestActive{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= M * active[k,t];

# 10% uplift from origin venue attendance to destination
subject to ExtraTicketCap{i in V, k in V, t in T: i <> k}:
    extra[i,k,t] <= 0.10 * sum{j in S} sold[i,j,t];
