"""
VERIF_05: X^{p,q} LPS Graph Construction Validation

Purpose:
  Construct the LPS graph X^{p,q} as a multigraph on P^1(F_q) and validate
  its Ramanujan properties.

Graph Construction:
  Vertices: P^1(F_q) = F_q ∪ {∞}, size = q + 1
  Edges: For each generator M and vertex x, add edge {x, M(x)}
  
  Important: Since generators come in conjugate pairs (M, M^{-1}), we use
  the adjacency matrix construction with rule i < j for non-loop edges
  to avoid double counting (per DeepSeek's analysis).

Required Properties:
  1. Graph is (p+1)-regular (including loops counted once)
  2. Largest eigenvalue λ₁ = p + 1
  3. Ramanujan bound: |λ| ≤ 2√p for all λ ≠ ±λ₁
  4. Graph is connected (multiplicity of λ₁ = 1)

Mathematical Background:
  X^{p,q} is a Cayley graph on PSL(2, F_q) with generators from quaternion
  solutions of norm p. By LPS theorem (1988), it is a Ramanujan graph.
  Self-loops are structural features (not bugs) from diagonal generators.

Reference:
  Lubotzky, Phillips, Sarnak. "Ramanujan Graphs." Combinatorica 8(3), 1988.

Author: EPMP-LPS Project
Date: 2026-07-08
"""

# CONFIGURATION
p = 5
q = 13

# HELPER FUNCTIONS

def even_numbers_up_to(N):
    """Generate even numbers from -N to N. Return: list"""
    N = int(N)
    if N % 2 == 0:
        return list(range(-N, N+1, 2))
    else:
        return list(range(-(N-1), N, 2))


def get_quaternion_solutions(p):
    """Find all quaternion solutions for given p. Return: list of tuples"""
    solutions = []
    max_val = int(p**0.5)
    
    for a in range(1, max_val + 1, 2):
        for b in even_numbers_up_to(max_val):
            for c in even_numbers_up_to(max_val):
                for d in even_numbers_up_to(max_val):
                    if a*a + b*b + c*c + d*d == p:
                        solutions.append((a, b, c, d))
    
    return solutions


def get_matrices(solutions, q):
    """Convert quaternion solutions to matrices. Return: list of matrices"""
    Fq = GF(q)
    i = Fq(-1).sqrt()
    
    matrices = []
    for sol in solutions:
        a, b, c, d = sol
        a_f, b_f, c_f, d_f = Fq(a), Fq(b), Fq(c), Fq(d)
        
        M = matrix(Fq, 2, 2, [
            a_f + i * b_f,  c_f + i * d_f,
            -c_f + i * d_f, a_f - i * b_f
        ])
        matrices.append(M)
    
    return matrices


def mobius_action(M, x):
    """Compute M·x = (Ax + B) / (Cx + D). Return: element of P^1(F_q)"""
    A, B, C, D = M[0, 0], M[0, 1], M[1, 0], M[1, 1]
    
    if x == 'inf':
        if C == 0:
            return 'inf'
        else:
            return A / C
    else:
        denom = C * x + D
        if denom == 0:
            return 'inf'
        else:
            return (A * x + B) / denom


# CONSTRUCT GRAPH

solutions = get_quaternion_solutions(p)
matrices = get_matrices(solutions, q)

Fq = GF(q)
P1 = list(range(q)) + ['inf']
n = q + 1

# Build adjacency matrix with proper counting (avoid double counting)
A = matrix(ZZ, n, n, 0)

for M in matrices:
    for idx_i, x in enumerate(P1):
        y = mobius_action(M, x)
        idx_j = P1.index(y)
        
        if idx_i == idx_j:
            # Self-loop: count once
            A[idx_i, idx_i] += 1
        elif idx_i < idx_j:
            # Non-loop edge: count once (avoid double counting from M and M^{-1})
            A[idx_i, idx_j] += 1
            A[idx_j, idx_i] += 1

# VALIDATION

print("[VERIF_05] X^{p,q} LPS Graph Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("  n = " + str(n) + " vertices")
print("")

# Check 1: Graph is (p+1)-regular
expected_degree = p + 1
degrees = [int(sum(A[i])) for i in range(n)]
regular_check = all(d == expected_degree for d in degrees)
print("  Graph is (p+1)-regular: " + str(regular_check))
print("    Expected degree: " + str(expected_degree))
print("    Actual degrees: " + str(set(degrees)))
print("")

# Check 2: Count self-loops
num_loops = int(A.trace())
print("  Number of self-loops: " + str(num_loops))
print("    (Self-loops are structural features of X^{p,q}, not bugs)")
print("")

# Check 3: Compute eigenvalues
eigs = A.eigenvalues()
eigs_sorted = sorted(eigs, reverse=True)

print("  Eigenvalues (first 10):")
for idx_e, ev in enumerate(eigs_sorted[:10]):
    print("    λ_" + str(idx_e+1) + " = " + str(ev))
if len(eigs_sorted) > 10:
    print("    ...")
print("")

# Check 4: λ₁ = p + 1
lambda_1 = eigs_sorted[0]
lambda_1_check = (abs(lambda_1 - expected_degree) < 0.01)
print("  λ₁ = p + 1: " + str(lambda_1_check))
print("    λ₁ = " + str(lambda_1))
print("    Expected: " + str(expected_degree))
print("")

# Check 5: Connectedness (multiplicity of λ₁ = 1)
multiplicity = sum(1 for ev in eigs if abs(ev - lambda_1) < 0.01)
connected_check = (multiplicity == 1)
print("  Graph is connected: " + str(connected_check))
print("    Multiplicity of λ₁: " + str(multiplicity))
print("")

# Check 6: Ramanujan bound
ramanujan_bound = 2 * sqrt(p)
max_nontrivial = 0
for ev in eigs:
    # Skip ±λ₁ (handle both positive and negative largest eigenvalues)
    if abs(abs(ev) - lambda_1) > 0.01:
        if abs(ev) > max_nontrivial:
            max_nontrivial = abs(ev)

ramanujan_check = (max_nontrivial <= ramanujan_bound + 0.01)
print("  Ramanujan bound satisfied: " + str(ramanujan_check))
print("    Bound: 2√p = " + str(ramanujan_bound))
print("    Max |λ| for |λ| ≠ λ₁: " + str(max_nontrivial))
print("")

# FINAL RESULT

all_checks = [regular_check, lambda_1_check, connected_check, ramanujan_check]
result = all(all_checks)

print("RESULT: " + str(result))
