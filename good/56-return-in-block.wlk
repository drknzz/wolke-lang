# (return in block)

def f() -> Void:
    if True:
        return

def main() -> Void:
    f()
    print("All good!")