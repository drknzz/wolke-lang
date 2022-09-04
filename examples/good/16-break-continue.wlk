# (break, continue)

def main() -> Void:
    Int x = 1
    Int i = 0

    while True:
        x = x * 2
        i = i + 1
        if i % 2 == 1:
            continue
        print(x)
        if x > 200:
            break