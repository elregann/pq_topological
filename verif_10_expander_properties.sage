"""
VERIF_10: Expander Properties Validation for Y^{p,q} Graph

Purpose:
  Verify that Y^{p,q} has strong expander properties, which provide the
  mathematical foundation for EPMP hardness.

Expander Properties:
  1. Spectral gap: λ₁ - λ₂ (larger is better)
  2. Diameter: O(log n) for expander graphs
  3. Mixing time: O(log n) for random walk convergence
  4. Edge expansion: computed only for small graphs (n ≤ 20)

Mathematical Background:
  Expander graphs have the property that every small subset has many edges
  going outside. This prevents local search algorithms (including SAT solvers)
  from exploiting local structure. The spectral gap quantifies this property
  algebraically.
  
  For Ramanujan graphs, the spectral gap is optimal: λ₂ ≤ 2√(d-1).
  This implies strong expansion and rapid mixing.

Author: EPMP-LPS Project
Date: 2026-07-08
"""

import math
from collections import deque

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


def bfs_distance(adj_matrix, start):
    """Compute shortest distances from start vertex using BFS."""
    n = adj_matrix.nrows()
    distances = [-1] * n
    distances[start] = 0
    queue = deque([start])
    
    while queue:
        u = queue.popleft()
        for v in range(n):
            if adj_matrix[u, v] != 0 and distances[v] == -1:
                distances[v] = distances[u] + 1
                queue.append(v)
    
    return distances


# CONSTRUCT Y^{p,q} GRAPH

solutions = get_quaternion_solutions(p)
matrices = get_matrices(solutions, q)

Fq = GF(q)
P1 = list(range(q)) + ['inf']
n_ypq = 2 * (q + 1)

# Build adjacency matrix
A = matrix(ZZ, n_ypq, n_ypq, 0)

for M in matrices:
    for idx_x, x in enumerate(P1):
        y = mobius_action(M, x)
        idx_y = P1.index(y)
        
        u = idx_x
        v = idx_y + (q + 1)
        
        A[u, v] += 1
        A[v, u] += 1

# VALIDATION

print("[VERIF_10] Expander Properties Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("  n = " + str(n_ypq) + " vertices")
print("  d = " + str(p+1) + " (degree)")
print("")

# Check 1: Spectral gap
eigs = A.eigenvalues()
eigs_sorted = sorted(eigs, reverse=True)

lambda_1 = eigs_sorted[0]
lambda_2 = eigs_sorted[1]

spectral_gap = lambda_1 - lambda_2

# Ramanujan bound
ramanujan_bound = 2 * sqrt(p)
ramanujan_check = (abs(lambda_2) <= ramanujan_bound + 0.01)

print("  Spectral gap: " + str(spectral_gap))
print("    λ₁ = " + str(lambda_1))
print("    λ₂ = " + str(lambda_2))
print("  Ramanujan bound: |λ₂| ≤ 2√p = " + str(ramanujan_bound))
print("  Ramanujan property: " + str(ramanujan_check))
print("")

# Check 2: Edge expansion (Cheeger constant)
# Only compute for small graphs (n ≤ 20) to avoid exponential complexity
if n_ypq <= 20:
    from itertools import combinations
    
    min_expansion = float('inf')
    min_subset = None
    
    for size in range(1, n_ypq // 2 + 1):
        for subset in combinations(range(n_ypq), size):
            subset_set = set(subset)
            
            # Count edges leaving subset
            boundary_edges = 0
            for u in subset_set:
                for v in range(n_ypq):
                    if v not in subset_set and A[u, v] != 0:
                        boundary_edges += A[u, v]
            
            expansion = boundary_edges / size
            
            if expansion < min_expansion:
                min_expansion = expansion
                min_subset = subset
    
    cheeger_constant = min_expansion
    print("  Edge expansion (Cheeger constant):")
    print("    h(G) = " + str(cheeger_constant))
    print("    Min subset size: " + str(len(min_subset)))
    print("    Boundary edges: " + str(int(min_expansion * len(min_subset))))
else:
    cheeger_constant = None
    print("  Edge expansion: Skipped (n = " + str(n_ypq) + " > 20, exponential complexity)")
    print("    Note: Ramanujan property implies strong expansion theoretically")
print("")

# Check 3: Diameter
distances_from_0 = bfs_distance(A, 0)
diameter = max(distances_from_0)

# Theoretical bound for expander: O(log n)
theoretical_diameter = math.ceil(math.log(n_ypq) / math.log(p))

print("  Diameter:")
print("    Actual diameter: " + str(diameter))
print("    Theoretical bound: O(log n) ≈ " + str(theoretical_diameter))
print("    Diameter is small: " + str(diameter <= theoretical_diameter * 2))
print("")

# Check 4: Mixing time estimate
if spectral_gap > 0:
    mixing_time_estimate = math.log(n_ypq) / float(spectral_gap)
    print("  Mixing time estimate:")
    print("    τ ≈ log(n) / spectral_gap")
    print("    τ ≈ " + str(mixing_time_estimate))
    print("    Rapid mixing: " + str(mixing_time_estimate < 10))
else:
    mixing_time_estimate = None
    print("  Mixing time: Cannot compute (spectral gap = 0)")
print("")

# Summary
print("  Summary:")
print("    Spectral gap: " + str(spectral_gap))
print("    Ramanujan property: " + str(ramanujan_check))
if cheeger_constant is not None:
    print("    Edge expansion: " + str(cheeger_constant))
else:
    print("    Edge expansion: Skipped (too large)")
print("    Diameter: " + str(diameter))
if mixing_time_estimate is not None:
    print("    Mixing time: " + str(mixing_time_estimate))
print("")

# FINAL RESULT

# Expander properties are validated if:
# 1. Ramanujan property holds
# 2. Diameter is small
# 3. Spectral gap is positive

all_checks = [ramanujan_check, diameter <= theoretical_diameter * 2, spectral_gap > 0]
result = all(all_checks)

print("RESULT: " + str(result))
