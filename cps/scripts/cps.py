#!/usr/bin/env python3
# Streams "<left_cps> <right_cps>" lines to stdout whenever either count changes.
# Clicks are counted over a sliding 1-second window from every mouse evdev node.
import glob
import os
import select
import struct
import sys
import time
from collections import deque

EV_KEY = 1
BTN_LEFT = 0x110
BTN_RIGHT = 0x111
EVENT = struct.Struct("llHHi")
WINDOW = 1.0
TICK = 0.05
RESCAN = 3.0


def mouse_nodes():
    nodes = set()
    try:
        with open("/proc/bus/input/devices") as f:
            blocks = f.read().split("\n\n")
    except OSError:
        return nodes
    for block in blocks:
        for line in block.splitlines():
            if not line.startswith("H: Handlers="):
                continue
            handlers = line.split("=", 1)[1].split()
            if any(h.startswith("mouse") for h in handlers):
                nodes.update("/dev/input/" + h for h in handlers if h.startswith("event"))
    return nodes


def main():
    fds = {}  # path -> fd
    left, right = deque(), deque()
    last = None
    next_scan = 0.0

    while True:
        now = time.monotonic()
        if now >= next_scan:
            wanted = mouse_nodes()
            for path in list(fds):
                if path not in wanted:
                    os.close(fds.pop(path))
            for path in wanted - fds.keys():
                try:
                    fds[path] = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
                except OSError:
                    pass
            next_scan = now + RESCAN

        ready, _, _ = select.select(list(fds.values()), [], [], TICK)
        now = time.monotonic()
        for fd in ready:
            try:
                data = os.read(fd, EVENT.size * 64)
            except OSError:
                for path, f in list(fds.items()):
                    if f == fd:
                        os.close(fds.pop(path))
                continue
            for off in range(0, len(data) - EVENT.size + 1, EVENT.size):
                _, _, etype, code, value = EVENT.unpack_from(data, off)
                if etype == EV_KEY and value == 1:
                    if code == BTN_LEFT:
                        left.append(now)
                    elif code == BTN_RIGHT:
                        right.append(now)

        cutoff = now - WINDOW
        while left and left[0] < cutoff:
            left.popleft()
        while right and right[0] < cutoff:
            right.popleft()

        state = (len(left), len(right))
        if state != last:
            last = state
            sys.stdout.write(f"{state[0]} {state[1]}\n")
            sys.stdout.flush()


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        pass
