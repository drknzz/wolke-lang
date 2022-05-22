# (void as variable type)

String result = ""

def f() -> Void:
    result = result + "f() "

Void x = f()

def g() -> Void:
    result = result + "g() "
    return x

def h(a | Void) -> Void:
    Void b = a
    result = result + "h() "

def main() -> Void:
    g()
    h(f())
    print(result)
    assert(result == "f() g() f() h() ")