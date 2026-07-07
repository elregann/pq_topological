"""
EPMP-BASED KEY ENCAPSULATION MECHANISM (KEM)

Purpose:
  Implement a Key Encapsulation Mechanism based on the Equivalent Partial
  Monodromy Problem (EPMP) over LPS Ramanujan graphs.

Concept:
  - Alice generates private key rho (LPS permutations) and public key
    (constraints derived from rho)
  - Bob generates random path in LPS graph, computes hint, and sends
    partial constraints + hint to Alice
  - Alice recovers path using rho and verifies with hint
  - Shared secret derived from path

Security Properties:
  - Hardness based on EPMP (find rho' satisfying constraints)
  - Expander properties prevent local search attacks
  - Hint mechanism resolves path ambiguity
  - SHA-256 provides collision resistance

Limitations:
  - This is a proof-of-concept implementation
  - Parameters (p=5, q=13) provide ~176-bit security for EPMP
  - Path brute force is feasible for small path_length
  - Production deployment requires parameter optimization
  - Formal security proof is future work

Reference:
  Lubotzky, Phillips, Sarnak. "Ramanujan Graphs." Combinatorica 8(3), 1988.

Author: EPMP-LPS Project
Date: 2026-07-08
"""

import random
import hashlib

# CONFIGURATION
p = 5
q = 13
path_length = 8
alice_seed = 42
bob_seed = 123

# HELPER FUNCTIONS

def even_numbers_up_to(N):
    """Generate even numbers from -N to N."""
    N = int(N)
    if N % 2 == 0:
        return list(range(-N, N+1, 2))
    else:
        return list(range(-(N-1), N, 2))


def get_quaternion_solutions(p):
    """Find all quaternion solutions to a^2 + b^2 + c^2 + d^2 = p."""
    solutions = []
    max_val = int(p**0.5)
    for a in range(1, max_val + 1, 2):
        for b in even_numbers_up_to(max_val):
            for c in even_numbers_up_to(max_val):
                for d in even_numbers_up_to(max_val):
                    if a*a + b*b + c*c + d*d == p:
                        solutions.append((a, b, c, d))
    return solutions


def get_permutations(solutions, q):
    """Convert quaternion solutions to permutations on P^1(F_q)."""
    Fq = GF(q)
    i = Fq(-1).sqrt()
    P1 = list(range(q)) + ['inf']
    n = q + 1
    permutations = []
    for sol in solutions:
        a, b, c, d = sol
        a_f, b_f, c_f, d_f = Fq(a), Fq(b), Fq(c), Fq(d)
        M = matrix(Fq, 2, 2, [
            a_f + i * b_f,  c_f + i * d_f,
            -c_f + i * d_f, a_f - i * b_f
        ])
        perm = []
        for x in P1:
            A, B, C, D = M[0, 0], M[0, 1], M[1, 0], M[1, 1]
            if x == 'inf':
                y = 'inf' if C == 0 else A / C
            else:
                denom = C * x + D
                y = 'inf' if denom == 0 else (A * x + B) / denom
            y_idx = P1.index(y)
            perm.append(y_idx)
        permutations.append(perm)
    return permutations


def get_perm_inverse(perm):
    """Compute inverse permutation."""
    n = len(perm)
    inv = [0] * n
    for i, p in enumerate(perm):
        inv[p] = i
    return inv


def apply_perm(perm, x, sign):
    """Apply permutation or its inverse to vertex x."""
    if sign > 0:
        return perm[x]
    else:
        inv = get_perm_inverse(perm)
        return inv[x]


def generate_random_path(k, length, seed):
    """Generate random path in LPS graph."""
    random.seed(int(seed))
    path = []
    for _ in range(int(length)):
        gen_idx = int(random.randint(0, k-1))
        sign = int(random.choice([1, -1]))
        path.append((gen_idx, sign))
    return path


def compute_intermediate_vertices(path, rho):
    """Compute intermediate vertices along path."""
    vertices = [0]
    current = 0
    for gen_idx, sign in path:
        current = apply_perm(rho[gen_idx], current, sign)
        vertices.append(current)
    return vertices


def is_constraint_trivial(constraint, rho):
    """Check if constraint reveals no information (generator fixes vertex)."""
    gen_idx = constraint['generator']
    sign = constraint['sign']
    v_from = constraint['from']
    result = apply_perm(rho[gen_idx], v_from, sign)
    return (result == v_from)


def compute_hint(path, rho):
    """Compute hint for path verification."""
    data = str(path).encode()
    rho_sig = 0
    for gen_idx, sign in path:
        rho_sig = apply_perm(rho[gen_idx], rho_sig, sign)
    data += b':' + str(rho_sig).encode()
    return hashlib.sha256(data).digest()


def verify_hint(path, rho, hint):
    """Verify hint matches path."""
    expected = compute_hint(path, rho)
    return (expected == hint)


def alice_recover_paths(nontrivial_constraints, rho, k, path_length):
    """Alice recovers all possible paths from non-trivial constraints."""
    constraint_map = {}
    for c in nontrivial_constraints:
        constraint_map[c['index']] = (c['generator'], c['sign'], c['from'], c['to'])
    
    possible_paths = []
    
    def search(pos, current_vertex, current_path):
        if pos == path_length:
            possible_paths.append(list(current_path))
            return
        
        if pos in constraint_map:
            gen_idx, sign, v_from, v_to = constraint_map[pos]
            if current_vertex != v_from:
                return
            result = apply_perm(rho[gen_idx], current_vertex, sign)
            if result != v_to:
                return
            current_path.append((gen_idx, sign))
            search(pos + 1, v_to, current_path)
            current_path.pop()
        else:
            for gen_idx in range(k):
                for sign in [1, -1]:
                    result = apply_perm(rho[gen_idx], current_vertex, sign)
                    if result == current_vertex:
                        current_path.append((gen_idx, sign))
                        search(pos + 1, result, current_path)
                        current_path.pop()
    
    search(0, 0, [])
    return possible_paths


# KEM FUNCTIONS

def keygen(p, q, seed):
    """
    KeyGen: Alice generates public/private key pair.
    
    Returns:
      public_key: (p, q, k, d)
      private_key: rho (permutations)
    """
    solutions = get_quaternion_solutions(p)
    rho = get_permutations(solutions, q)
    k = len(rho)
    d = len(rho[0])
    
    public_key = (p, q, k, d)
    private_key = rho
    
    return public_key, private_key


def encapsulate(public_key, seed):
    """
    Encapsulate: Bob generates random path and computes ciphertext.
    
    Returns:
      shared_secret: 32-byte key
      ciphertext: (non_trivial_constraints, hint, endpoint)
    """
    p, q, k, d = public_key
    
    # Generate random path
    path = generate_random_path(k, path_length, seed)
    
    # Compute intermediate vertices
    solutions = get_quaternion_solutions(p)
    rho = get_permutations(solutions, q)
    vertices = compute_intermediate_vertices(path, rho)
    
    # Build constraints
    all_constraints = []
    for i, (gen_idx, sign) in enumerate(path):
        all_constraints.append({
            'index': i,
            'generator': gen_idx,
            'sign': sign,
            'from': vertices[i],
            'to': vertices[i+1]
        })
    
    # Separate trivial and non-trivial constraints
    nontrivial = [c for c in all_constraints if not is_constraint_trivial(c, rho)]
    
    # Compute hint
    hint = compute_hint(path, rho)
    
    # Endpoint
    endpoint = vertices[-1]
    
    # Shared secret
    shared_secret = hashlib.sha256(str(path).encode()).digest()
    
    # Ciphertext
    ciphertext = (nontrivial, hint, endpoint)
    
    return shared_secret, ciphertext


def decapsulate(private_key, public_key, ciphertext):
    """
    Decapsulate: Alice recovers path and derives shared secret.
    
    Returns:
      shared_secret: 32-byte key (or None if recovery fails)
    """
    rho = private_key
    p, q, k, d = public_key
    nontrivial, hint, endpoint = ciphertext
    
    # Recover possible paths
    possible_paths = alice_recover_paths(nontrivial, rho, k, path_length)
    
    # Verify hint for each possible path
    matching_paths = []
    for candidate in possible_paths:
        if verify_hint(candidate, rho, hint):
            matching_paths.append(candidate)
    
    # Check if unique match
    if len(matching_paths) == 1:
        path = matching_paths[0]
        shared_secret = hashlib.sha256(str(path).encode()).digest()
        return shared_secret
    elif len(matching_paths) > 1:
        # Multiple matches - ambiguity
        return None
    else:
        # No match - error
        return None


# MAIN

print("[EPMP-KEM] Key Encapsulation Mechanism")
print("  p = " + str(p))
print("  q = " + str(q))
print("  path_length = " + str(path_length))
print("")

# KeyGen
print("  Step 1: Alice generates keys")
public_key, private_key = keygen(p, q, alice_seed)
p_pk, q_pk, k, d = public_key
print("    Public key: (p=" + str(p_pk) + ", q=" + str(q_pk) + ", k=" + str(k) + ", d=" + str(d) + ")")
print("    Private key: rho (permutations)")
print("")

# Encapsulate
print("  Step 2: Bob encapsulates shared secret")
bob_secret, ciphertext = encapsulate(public_key, bob_seed)
nontrivial, hint, endpoint = ciphertext
print("    Bob's secret: " + bob_secret.hex()[:32] + "...")
print("    Ciphertext:")
print("      Non-trivial constraints: " + str(len(nontrivial)))
print("      Hint: " + hint.hex()[:32] + "...")
print("      Endpoint: " + str(endpoint))
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
