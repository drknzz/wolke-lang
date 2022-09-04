# (greatest common divisor)
# (least common multiple)

def gcd(a | Int, b | Int) -> Int:
    if b == 0:
        return a
    return gcd(b, a % b)


def lcm(a | Int, b | Int) -> Int:
    Int tmp = a

    while a % b != 0:
        a = a + tmp
    
    return a


def main() -> Void:
    Int a = 48
    Int b = 60

    Int GCD = gcd(a, b)
    Int LCM = lcm(a, b)

    print(GCD)
    print(LCM)

    assert(GCD == 12)
    assert(LCM == 240)