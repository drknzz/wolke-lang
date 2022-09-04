# (string multiplication)

def multiply_str(s | String&, x | Int) -> Void:
    String tmp = s

    while x > 1:
        s = s + tmp
        x = x - 1


def main() -> Void:
    String s = "aa"

    multiply_str(s, 3)
    print(s)
    assert(s == "aaaaaa")