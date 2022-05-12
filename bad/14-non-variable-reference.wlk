# (non-variable reference error)

def refer(x | Int, y | String&) -> Void:
    y = "xxx"

def f() -> String:
    return "bbb"

def main() -> Void:
    String x = "aaa"
    refer(5, f())
    print(x)