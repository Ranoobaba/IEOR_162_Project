from amplpy import AMPL, modules

modules.load()

# (model, data) pairs for each task
TASKS = [
    ("task1.mod", "task1.dat", ["x", "y"]),
    ("task2.mod", "task2.dat", ["x", "y", "z"]),
    ("task3.mod", "main.dat",  ["x", "y", "z", "sold"]),
    ("task4.mod", "main.dat",  ["x", "y", "z", "sold", "b", "extra"]),
]


def run(model_file, data_file, display_vars):
    print("\n" + "=" * 72)
    print(f"Running {model_file}  (data: {data_file})")
    print("=" * 72)
    ampl = AMPL()
    ampl.read(model_file)
    ampl.read_data(data_file)
    ampl.option["solver"] = "highs"
    ampl.option["solver_msg"] = 0
    ampl.solve()
    status = ampl.solve_result
    print(f"Solver status: {status}")
    print(f"TotalCost = {ampl.get_objective('TotalCost').value():.2f} (thousand $)")

    for name in display_vars:
        try:
            var = ampl.get_variable(name)
        except Exception as e:
            print(f"  (no variable {name}: {e})")
            continue
        rows = []
        for key, val in var.get_values().to_dict().items():
            if abs(val) > 1e-6:
                rows.append((key, val))
        if not rows:
            print(f"\n{name}: (all zero)")
        else:
            print(f"\n{name} (nonzero):")
            for k, v in sorted(rows, key=lambda r: str(r[0])):
                print(f"  {k} = {v:g}")


if __name__ == "__main__":
    for m, d, v in TASKS:
        run(m, d, v)
