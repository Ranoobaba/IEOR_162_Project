from amplpy import AMPL, modules

modules.load()

TASKS = ["task1.mod", "task2.mod", "task3.mod", "task4.mod"]
DISPLAY_BY_TASK = {
    "task1.mod": ["x", "y"],
    "task2.mod": ["x", "y", "z"],
    "task3.mod": ["x", "y", "z", "sold"],
    "task4.mod": ["x", "y", "z", "sold", "b", "extra"],
}


def run(model_file):
    print("\n" + "=" * 60)
    print(f"Running {model_file}")
    print("=" * 60)
    ampl = AMPL()
    ampl.read(model_file)
    ampl.read_data("main.dat")
    ampl.option["solver"] = "highs"
    ampl.solve()

    print(f"TotalCost = {ampl.get_objective('TotalCost').value():.2f}")
    for name in DISPLAY_BY_TASK[model_file]:
        var = ampl.get_variable(name)
        df = var.get_values().to_pandas()
        nz = df[df.iloc[:, 0].abs() > 1e-6]
        if nz.empty:
            print(f"\n{name}: (all zero)")
        else:
            print(f"\n{name} (nonzero entries):")
            print(nz.to_string())


if __name__ == "__main__":
    for t in TASKS:
        run(t)
