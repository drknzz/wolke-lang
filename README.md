# Wolke

--- Opis języka ---

Opis języka znajduje się w pliku WolkeDescription.pdf


--- Opis rozwiązania ---

Interpreter przechodzi przez 3 etapy:
    1. Sprawdzenie poprawności składni      |   etap wykonywany przez pliki w folderze /Gen
    2. Sprawdzenie statycznego typowania    |   etap wykonywany przez plik TypeChecker.hs
    3. Interpretacja oraz ewaluacja kodu    |   etap wykonywany przez plik Interpreter.hs

Pliki w folderze /Gen to pliki wygenerowane przez program bnfc z opcją --functor.

Etapy 2. oraz 3. operują na własnych monadach zdefiniowanych odpowiednio do potrzeb danego etapu:
Etap 2. -> Środowisko (Nazwa, Typ)
Etap 3. -> Środowisko (Nazwa, Lokacja) + Skład ((Lokacja, Wartość), Ostatnia Wolna Lokacja)


--- Przykłady ---

Przykłady złych programów, które powinny zakończyć się błędem znajdują się w folderze /bad.
Przykłady dobrych programów, które powinny zakończyć się poprawnie znajdują się w folderze /good.


--- Uruchomienie interpretera ---

make
./interpreter <ścieżka_do_pliku>.wlk