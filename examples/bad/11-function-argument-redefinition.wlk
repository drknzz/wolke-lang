# (function argument redefinition)

def f(x | Int) -> Void:
    Int x = 5
    print(x)

def main() -> Void:
    Int x = 1
    f(x)