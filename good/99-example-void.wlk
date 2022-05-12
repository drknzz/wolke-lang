# (void as variable type)

def f() -> Void:
    pass

Void x = f()

def g() -> Void:
    return x

def main() -> Void:
    g()
    print("This is intended behaviour")