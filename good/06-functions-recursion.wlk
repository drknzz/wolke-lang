# (functions, recursion)

def fib(n | Int) -> Int:
    if n == 0 or n == 1:
        return n
    return fib(n - 1) + fib(n - 2)

def nothing() -> Void:
    pass

def main() -> Void:
    nothing()
    Int res = fib(15)
    assert(res == 610)
    print(res)