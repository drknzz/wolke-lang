# (functions returning value)

def add_or_sub(x | Int, y | Int, add | Boolean) -> Int:
    Int res = 0
    if add:
        res = x + y
    else:
        res = x - y
    return res

def main() -> Void:
    print(add_or_sub(6, 5, False))