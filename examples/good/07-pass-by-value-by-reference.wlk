/*
    (pass by value, pass by reference)
*/

def incVal(x | Int) -> Int:
    return x + 1

def incRef(y | Int&) -> Void:
    y = y + 1

def main() -> Void:
    Int x = 6
    print(incVal(x))
    incRef(x)
    assert(x == 7)