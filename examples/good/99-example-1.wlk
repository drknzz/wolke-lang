# (calculate the square root of 1234)

def sqrt(x | Int) -> Int:
    assert(x >= 0)
    Int l = 0
    Int r = x

    while l < r:
        Int m = l + (r - l + 1) / 2
        if m * m <= x:
            l = m
        else:
            r = m - 1
    
    return l


def main() -> Void:
    Int x = 1234
    Int root = sqrt(x)
    print(root)
    assert(root == 35)