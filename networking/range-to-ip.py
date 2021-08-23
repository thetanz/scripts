#!/usr/bin/env python
'''./range2ip.py 192.168.1.1 192.168.2.255'''

import sys

def generate(start, stop):
    for d in range(int(start[3]), int(stop[3]) + 1):
        for c in range(int(start[2]), int(stop[2]) + 1):
            for b in range(int(start[1]), int(stop[1]) + 1):
                for a in range(int(start[0]), int(stop[0]) + 1):
                    res = "{}.{}.{}.{}".format(a, b, c, d)
                    print(res)
    return

if __name__ == "__main__":
    start = sys.argv[1].split(".")
    stop = sys.argv[2].split(".")
    generate(start, stop)
