# (no return)

def f(i | Int) -> Void:
    if i == 1000:
        return
    return f(i + 1)

def main() -> Void:
    f(0)
    print("All good!")