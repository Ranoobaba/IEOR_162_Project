"""Task 5: Sensitivity analysis.

Solves task5.mod under four scenarios (A=baseline, B=low profit,
C=high profit, D=overestimated demand) and then evaluates each
scenario's optimal first-stage decisions (x, y, z, b) under every
other scenario's economics, producing a 4x4 cross-evaluation matrix.
"""
from amplpy import AMPL, modules

modules.load()

SCENARIOS = [
    ("A", "baseline (p=10, df=1.0)", 10.0, 1.0),
    ("B", "low profit (p=5)",         5.0, 1.0),
    ("C", "high profit (p=15)",      15.0, 1.0),
    ("D", "demand -10% (df=0.9)",    10.0, 0.9),
]


def build():
    a = AMPL()
    a.read("task5.mod")
    a.read_data("main.dat")
    a.option["solver"] = "highs"
    a.option["solver_msg"] = 0
    return a


def solve_free(p, df):
    a = build()
    a.param["p"] = p
    a.param["demand_factor"] = df
    a.solve()
    obj = a.get_objective("TotalCost").value()
    sol = {
        "x": dict(a.get_variable("x").get_values().to_dict()),
        "y": dict(a.get_variable("y").get_values().to_dict()),
        "z": dict(a.get_variable("z").get_values().to_dict()),
        "b": dict(a.get_variable("b").get_values().to_dict()),
    }
    venues_open = sorted(k for k, v in sol["x"].items() if v > 0.5)
    bus_pairs = sorted(
        tuple(sorted([i, k]))
        for (i, k), v in sol["b"].items()
        if v > 0.5
    )
    bus_pairs = sorted(set(bus_pairs))
    return obj, sol, venues_open, bus_pairs


def evaluate_fixed(sol, p, df):
    """Plug first-stage binaries from `sol` into a fresh model with (p, df)."""
    a = build()
    a.param["p"] = p
    a.param["demand_factor"] = df
    for name in ("x", "y", "z", "b"):
        var = a.get_variable(name)
        for key, val in sol[name].items():
            var[key].fix(round(val))
    a.solve()
    if a.solve_result != "solved":
        return float("nan")
    return a.get_objective("TotalCost").value()


def main():
    print("\n" + "=" * 78)
    print("TASK 5 — SENSITIVITY ANALYSIS")
    print("=" * 78)

    results = {}
    for tag, desc, p, df in SCENARIOS:
        print(f"\n[Solve {tag}] {desc}")
        obj, sol, venues, pairs = solve_free(p, df)
        results[tag] = dict(obj=obj, sol=sol, venues=venues, pairs=pairs, p=p, df=df, desc=desc)
        print(f"  objective      = {obj:+.2f}  (thousand $)")
        print(f"  venues opened  = {', '.join(venues)}")
        print(f"  bus pairs      = {pairs if pairs else '(none)'}")

    print("\n" + "=" * 78)
    print("CROSS-EVALUATION MATRIX")
    print("Rows = solution from scenario X, Cols = economics of scenario Y")
    print("Cell = total cost when X's x/y/z/b are applied under Y's (p, df)")
    print("Diagonal should match each scenario's own optimal objective.")
    print("=" * 78)

    header = f"{'':12}" + "".join(f"{tag:>14}" for tag, *_ in SCENARIOS)
    print(header)
    for tag_row, *_ in SCENARIOS:
        row_vals = []
        for tag_col, _, p, df in SCENARIOS:
            val = evaluate_fixed(results[tag_row]["sol"], p, df)
            row_vals.append(val)
        row = f"{tag_row:12}" + "".join(f"{v:+14.2f}" for v in row_vals)
        print(row)

    print("\nLegend:")
    for tag, desc, *_ in SCENARIOS:
        print(f"  {tag}: {desc}")

    print("\nScenario summary:")
    for tag, r in results.items():
        delta_vs_A = r["obj"] - results["A"]["obj"]
        print(f"  {tag} ({r['desc']})")
        print(f"    optimal   = {r['obj']:+.2f}")
        print(f"    Δ vs. A   = {delta_vs_A:+.2f}")
        print(f"    venues    = {', '.join(r['venues'])}")
        print(f"    bus pairs = {r['pairs']}")

    return results


if __name__ == "__main__":
    main()
