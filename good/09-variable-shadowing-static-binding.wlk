# (variable shadowing, static binding)
# (global, local variables)

String s = "global"

def check() -> Void:
    assert(s == "global")

def main() -> Void:
    assert(s == "global")

    String s = "local"
    
    assert(s == "local")
    
    print(s)