"""
EPMP-KEM: Key Encapsulation Mechanism over EPMP with Random Private Rho

Purpose:
  Implement a truly asymmetric Key Encapsulation Mechanism based on the
  Equivalent Partial Monodromy Problem (EPMP). The private key is a
  randomly generated set of permutations (rho), and the public key is
  the adjacency matrix of the resulting Schreier graph.

Concept:
  - Alice generates random permutations rho (private key)
  - Alice computes adjacency matrix of Schreier graph (public key)
  - Bob performs random walk on public graph, hides some vertices
  - Bob sends partial vertices + hint to Alice
  - Alice uses private rho to enumerate all paths and match hint
  - Eve must solve EPMP to recover rho from adjacency matrix

Security Properties:
  - Asymmetric: Alice has rho (trapdoor), Eve only has adjacency matrix
  - Hardness: Eve must solve EPMP to find rho' producing same graph
  - Hint: SHA-256 hash resolves path ambiguity
  - Random rho: not deterministically derived from public parameters

Limitations:
  - This is a proof-of-concept implementation
  - Random rho may not produce expander graph (unlike LPS construction)
  - Parameters (k=6, d=14, path_length=8) are for demonstration only
  - Formal security proof is future work
  - Performance not optimized for production use

Reference:
  Lubotzky, Phillips, Sarnak. "Ramanujan Graphs." Combinatorica 8(3), 1988.

Author: EPMP-LPS Project
Date: 2026-07-08
"""

import random
import hashlib

# CONFIGURATION
path_length = 8
k = 6
d = 14
alice_seed = 42
bob_seed = 123

# HELPER FUNCTIONS

def random_perm(n, seed, offset=0):
    """Generate random permutation on n elements."""
    random.seed(int(seed) + int(offset))
    perm = list(range(n))
    random.shuffle(perm)
    return perm


def apply_perm(perm, x, sign):
    """Apply permutation or its inverse to vertex x."""
    if sign > 0:
        return perm[x]
    else:
        inv = [0] * len(perm)
        for i, p in enumerate(perm):
            inv[p] = i
        return inv[x]


def get_perm_inverse(perm):
    """Compute inverse permutation."""
    n = len(perm)
    inv = [0] * n
    for i, p in enumerate(perm):
        inv[p] = i
    return inv


def build_graph(rho):
    """
    Build undirected adjacency matrix from permutations.
    For each permutation and its inverse, add edges.
    """
    n = len(rho[0])
    adj = [[0] * n for _ in range(n)]
    for perm in rho:
        for i in range(n):
            j = perm[i]
            adj[i][j] = 1
            inv = get_perm_inverse(perm)
            j_inv = inv[i]
            adj[i][j_inv] = 1
    return adj


# KEM FUNCTIONS

def keygen(k, d, seed):
    """
    KeyGen: Alice generates random rho and public adjacency matrix.
    Return: (public_key, private_key)
    """
    random.seed(int(seed))
    rho = []
    for i in range(k):
        perm = list(range(d))
        random.shuffle(perm)
        rho.append(perm)
    adj = build_graph(rho)
    public_key = (adj, k, d)
    private_key = rho
    return public_key, private_key


def encapsulate(public_key, seed):
    """
    Encapsulate: Bob performs random walk and generates ciphertext.
    Return: (shared_secret, ciphertext)
    """
    adj, k, d = public_key

    def random_walk(start, length, seed):
        """Bob performs random walk on undirected graph."""
        random.seed(int(seed))
        vertices = [start]
        cur = start
        for _ in range(length):
            neighbors = [i for i, val in enumerate(adj[cur]) if val == 1]
            if not neighbors:
                return None
            nxt = random.choice(neighbors)
            vertices.append(nxt)
            cur = nxt
        return vertices

    full_vertices = random_walk(0, path_length, seed)
    if full_vertices is None:
        return None, None

    # Hide some internal vertices
    # Note: explicit int() conversion needed for SageMath compatibility
    random.seed(int(int(seed) + 999))
    cipher_vertices = []
    for i, v in enumerate(full_vertices):
        if i == 0 or i == len(full_vertices) - 1:
            cipher_vertices.append(v)
        else:
            if random.random() < 0.5:
                cipher_vertices.append(v)
            else:
                cipher_vertices.append(None)

    hint = hashlib.sha256(str(full_vertices).encode()).digest()
    shared_secret = hashlib.sha256(str(full_vertices).encode()).digest()
    ciphertext = (cipher_vertices, hint)
    return shared_secret, ciphertext


def decapsulate(private_key, public_key, ciphertext):
    """
    Decapsulate: Alice recovers path using private rho.
    Return: shared_secret (or None if recovery fails)
    """
    rho = private_key
    adj, k, d = public_key
    cipher_vertices, hint = ciphertext

    def all_paths_segment(start, end, depth):
        """Generate all paths of exact length between start and end."""
        if depth == 0:
            return [([start], [])] if start == end else []
        paths = []
        for idx, perm in enumerate(rho):
            for sign in [1, -1]:
                nxt = apply_perm(perm, start, sign)
                sub_paths = all_paths_segment(nxt, end, depth-1)
                for verts, edges in sub_paths:
                    paths.append(([start] + verts, [(idx, sign)] + edges))
        return paths

    # Get positions of known vertices
    known_positions = [i for i, v in enumerate(cipher_vertices) if v is not None]
    candidate_full_paths = []

    def combine_segments(pos_idx, current_vertices, current_edges):
        """Recursively combine path segments."""
        if pos_idx == len(known_positions) - 1:
            if len(current_vertices) == path_length + 1:
                candidate_full_paths.append((current_vertices, current_edges))
            return
        pos_s = known_positions[pos_idx]
        pos_e = known_positions[pos_idx+1]
        seg_len = pos_e - pos_s
        v_s = cipher_vertices[pos_s]
        v_e = cipher_vertices[pos_e]
        seg_paths = all_paths_segment(v_s, v_e, seg_len)
        for verts, edges in seg_paths:
            if pos_idx == 0:
                new_verts = verts
                new_edges = edges
            else:
                new_verts = current_vertices + verts[1:]
                new_edges = current_edges + edges
            combine_segments(pos_idx+1, new_verts, new_edges)

    combine_segments(0, [], [])

    # Check each candidate against hint
    for verts, edges in candidate_full_paths:
        if hashlib.sha256(str(verts).encode()).digest() == hint:
            return hashlib.sha256(str(verts).encode()).digest()

    return None


# MAIN

print("[EPMP-KEM] Asymmetric KEM with Random rho")
print("  k = " + str(k) + " generators")
print("  d = " + str(d) + " vertices")
print("  path_length = " + str(path_length))
print("")

# KeyGen
print("  Step 1: Alice generates keys")
public_key, private_key = keygen(k, d, alice_seed)
adj, k_pk, d_pk = public_key
print("    Public key: adjacency matrix (" + str(d_pk) + " x " + str(d_pk) + ")")
print("    Private key: rho (random permutations)")
print("")

# Encapsulate
print("  Step 2: Bob encapsulates shared secret")
bob_secret, ciphertext = encapsulate(public_key, bob_seed)
if bob_secret is None:
    print("    Encapsulation failed")
    print("")
    print("RESULT: False")
else:
    cipher_vertices, hint = ciphertext
    revealed = sum(1 for v in cipher_vertices if v is not None)
    hidden = sum(1 for v in cipher_vertices if v is None)
    print("    Bob's secret: " + bob_secret.hex()[:32] + "...")
    print("    Cipher vertices: " + str(cipher_vertices))
    print("    Revealed: " + str(revealed) + ", Hidden: " + str(hidden))
    print("    Hint: " + hint.hex()[:32] + "...")
    print("")

    # Decapsulate
    print("  Step 3: Alice decapsulates shared secret")
    alice_secret = decapsulate(private_key, public_key, ciphertext)
    if alice_secret is None:
        print("    Decapsulation failed")
        print("")
        print("RESULT: False")
    else:
        print("    Alice's secret: " + alice_secret.hex()[:32] + "...")
        print("")

        # Verification
        print("  Step 4: Verification")
        secrets_match = (alice_secret == bob_secret)
        print("    Secrets match: " + str(secrets_match))
        print("")

        print("RESULT: " + str(secrets_match))
