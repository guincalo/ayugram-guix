#!/usr/bin/env python3
"""Compute the Guix/Nix recursive sha256 (nix-base32) of a directory,
excluding entries named .git, matching the output of
Guix's git-fetch (and `guix hash -rx` for ordinary trees)."""
import hashlib, os, stat, struct, sys

def s(h, b):
    if isinstance(b, str): b = b.encode()
    h.update(struct.pack('<Q', len(b))); h.update(b)
    pad = (8 - len(b) % 8) % 8
    h.update(b'\0' * pad)

def node(h, p):
    st = os.lstat(p)
    s(h, '(')
    if stat.S_ISLNK(st.st_mode):
        s(h, 'type'); s(h, 'symlink'); s(h, 'target'); s(h, os.readlink(p).encode())
    elif stat.S_ISDIR(st.st_mode):
        s(h, 'type'); s(h, 'directory')
        for n in sorted(os.listdir(p).__iter__(), key=lambda x: x.encode()):
            if n == '.git': continue  # git-fetch drops only .git
            s(h, 'entry'); s(h, '('); s(h, 'name'); s(h, n); s(h, 'node')
            node(h, os.path.join(p, n)); s(h, ')')
    else:
        s(h, 'type'); s(h, 'regular')
        if st.st_mode & 0o100: s(h, 'executable'); s(h, '')
        s(h, 'contents')
        size = st.st_size
        h.update(struct.pack('<Q', size))
        with open(p, 'rb') as f:
            while True:
                c = f.read(1 << 20)
                if not c: break
                h.update(c)
        h.update(b'\0' * ((8 - size % 8) % 8))
    s(h, ')')

def nix32(b):
    chars = "0123456789abcdfghijklmnpqrsvwxyz"
    l = (len(b) * 8 - 1) // 5 + 1
    out = []
    for n in range(l - 1, -1, -1):
        bit = n * 5; i = bit // 8; j = bit % 8
        c = b[i] >> j
        if i + 1 < len(b): c |= b[i + 1] << (8 - j)
        out.append(chars[c & 0x1f])
    return ''.join(out)

h = hashlib.sha256(); s(h, 'nix-archive-1'); node(h, sys.argv[1])
print(nix32(h.digest()))
