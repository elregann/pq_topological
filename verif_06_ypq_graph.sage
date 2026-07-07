"""
VERIF_06: Y^{p,q} Bipartite Double Cover Graph Validation

Purpose:
  Construct the bipartite double cover Y^{p,q} of X^{p,q} and validate
  its properties as a simple Ramanujan graph.

Graph Construction:
  Vertices: {(x, 0) : x ∈ P^1(F_q)} ∪ {(x, 1) : x ∈ P^1(F_q)}
           Total: 2(q+1) vertices
  Edges: For each generator M and vertex x, add edge {(x, 0), (M(x), 1)}
  
  This construction eliminates self-loops from X^{p,q} by creating a
  bipartite structure where edges only go between partition 0 and partition 1.

Required Properties:
  1. Graph is (p+1)-regular
  2. Graph is simple (no self-loops, no multiple edges)
  3. Graph is bipartite
  4. Graph is connected (multiplicity of λ₁ = 1)
  5. Ramanujan bound: |λ| ≤ 2√p for all non-trivial eigenvalues

Mathematical Background:
  Y^{p,q} is the bipartite double cover of X^{p,q}. It inherits the
  Ramanujan property from X^{p,q} while being a simple graph. The
  bipartite structure ensures spectrum is symmetric around 0.

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
n_ypq = 2 * (q + 1)  # Total vertices in Y^{p,q}

# Build adjacency matrix for Y^{p,q}
A = matrix(ZZ, n_ypq, n_ypq, 0)

for M in matrices:
    for idx_x, x in enumerate(P1):
        y = mobius_action(M, x)
        idx_y = P1.index(y)
        
        # Edge between (x, 0) and (y, 1)
        u = idx_x  # (x, 0)
        v = idx_y + (q + 1)  # (y, 1)
        
        A[u, v] += 1
        A[v, u] += 1  # Undirected edge

# VALIDATION

print("[VERIF_06] Y^{p,q} Bipartite Double Cover Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("  n = " + str(n_ypq) + " vertices")
print("")

# Check 1: Graph is (p+1)-regular
expected_degree = p + 1
degrees = [int(sum(A[i])) for i in range(n_ypq)]
regular_check = all(d == expected_degree for d in degrees)
print("  Graph is (p+1)-regular: " + str(regular_check))
print("    Expected degree: " + str(expected_degree))
print("    Actual degrees: " + str(set(degrees)))
print("")

# Check 2: Graph is simple (no self-loops)
num_loops = int(A.trace())
simple_check = (num_loops == 0)
print("  Graph is simple (no self-loops): " + str(simple_check))
print("    Number of self-loops: " + str(num_loops))
print("")

# Check 3: Graph is bipartite
# Partition 0: indices 0 to q
# Partition 1: indices q+1 to 2q+1
partition_0 = list(range(q + 1))
partition_1 = list(range(q + 1, 2 * (q + 1)))

bipartite_check = True
for i in partition_0:
    for j in partition_0:
        if A[i, j] != 0:
            bipartite_check = False
            break
for i in partition_1:
    for j in partition_1:
        if A[i, j] != 0:
            bipartite_check = False
            break

print("  Graph is bipartite: " + str(bipartite_check))
print("")

# Check 4: Compute eigenvalues
eigs = A.eigenvalues()
eigs_sorted = sorted(eigs, reverse=True)

print("  Eigenvalues (first 10):")
for idx_e, ev in enumerate(eigs_sorted[:10]):
    print("    λ_" + str(idx_e+1) + " = " + str(ev))
if len(eigs_sorted) > 10:
    print("    ...")
print("")

# Check 5: λ₁ = p + 1
lambda_1 = eigs_sorted[0]
lambda_1_check = (abs(lambda_1 - expected_degree) < 0.01)
print("  λ₁ = p + 1: " + str(lambda_1_check))
print("    λ₁ = " + str(lambda_1))
print("    Expected: " + str(expected_degree))
print("")

# Check 6: Connectedness (multiplicity of λ₁ = 1)
multiplicity = sum(1 for ev in eigs if abs(ev - lambda_1) < 0.01)
connected_check = (multiplicity == 1)
print("  Graph is connected: " + str(connected_check))
print("    Multiplicity of λ₁: " + str(multiplicity))
print("")

# Check 7: Ramanujan bound
ramanujan_bound = 2 * sqrt(p)
max_nontrivial = 0
for ev in eigs:
    # Skip ±λ₁ (handle bipartite spectrum symmetry)
    if abs(abs(ev) - lambda_1) > 0.01:
        if abs(ev) > max_nontrivial:
            max_nontrivial = abs(ev)

ramanujan_check = (max_nontrivial <= ramanujan_bound + 0.01)
print("  Ramanujan bound satisfied: " + str(ramanujan_check))
print("    Bound: 2√p = " + str(ramanujan_bound))
print("    Max |λ| for |λ| ≠ λ₁: " + str(max_nontrivial))
print("")

# FINAL RESULT

all_checks = [regular_check, simple_check, bipartite_check, lambda_1_check, 
              connected_check, ramanujan_check]
result = all(all_checks)

print("RESULT: " + str(result))
