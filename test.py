from imghdr import tests
import os
import subprocess

cmds = ['cd generated && bnfc -m --functor ../Wolke.cf && make']

for cmd in cmds:
    os.system(cmd)

tests = os.listdir('good')
passed = 0
failed_arr = []

for test in tests:
    with open(f'good/{test}') as f:
        text = f.read()
    out = subprocess.run(f'echo "{text}" | ./generated/TestWolke', shell=True, stdout=subprocess.PIPE).stdout.decode('utf-8')
    if out.find('Parse Successful!') != -1:
        passed += 1
    else:
        failed_arr.append(f'\n------------ {test} ------------\n\n{text}\n{out}\n')

print('\n\n------------ RESULTS ------------')
print(f'PASSED: {passed} / {len(tests)}')
if failed_arr:
    print('\nFAILURES OCCURED!')
    for x in failed_arr:
        print(x)