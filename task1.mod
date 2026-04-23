# =========================================================
# Task 1: Venue Selection & Sport Assignment
# Goal: Pick which of the 10 candidate venues to open and
# assign each of the 15 sports to exactly one eligible
# open venue at minimum total fixed cost.
#
# What's new (baseline model):
#   Sets:        V (venues), S (sports)
#   Params:      c[V] (fixed cost), a[V,S] (eligibility)
#   Variables:   x[V] (open?), y[V,S] (assignment)
#   Objective:   minimize sum c_i * x_i
#   Constraints: AssignEachSport, OpenLink, Eligibility
# =========================================================

set V;                       # candidate venues (V1..V10 from Table 1)
set S;                       # Olympic sports (S1..S15 from Table 2)

param c{V} >= 0;             # c_i: one-time utilization cost of venue i (thousand $)
param a{V,S} binary;         # a_ij: 1 if venue i is eligible to host sport j (Table 3)

var x{V} binary;             # x_i = 1 if venue i is opened, 0 otherwise
var y{V,S} binary;           # y_ij = 1 if sport j is assigned to venue i

# Objective: minimize the total fixed cost of opened venues
minimize TotalCost:
    sum{i in V} c[i] * x[i];

# Every sport must be assigned to exactly one venue
subject to AssignEachSport{j in S}:
    sum{i in V} y[i,j] = 1;

# A sport can only be assigned to a venue that is actually opened
subject to OpenLink{i in V, j in S}:
    y[i,j] <= x[i];

# A sport can only be assigned to a venue that is eligible (a_ij = 1)
subject to Eligibility{i in V, j in S}:
    y[i,j] <= a[i,j];
