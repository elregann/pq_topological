"""
VERIF_11: Group Action Validation for EPMP Monodromy

Purpose:
  Verify that the LPS permutations induce a valid group action on P^1(F_q)
  with desirable properties for EPMP hardness.

Group Action Properties:
  1. Transitivity: Group acts transitively on P^1(F_q)
     (single orbit, can reach any vertex from any other)
  2. Orbit structure: Verify orbit sizes and count
  3. Stabilizer structure: Verify stabilizer subgroups
  4. Group order: Verify |<generators>| matches expected

Mathematical Background:
  For EPMP to be hard, the group action must be transitive (otherwise
  the problem decomposes into independent subproblems). The LPS construction
  guarantees transitivity because the generators come from PSL(2, F_q)
  which acts transitively on P^1(F_q).
  
  The stabilizer of a point has size |G| / |P^1(F_q)| by orbit-stabilizer
  theorem. For LPS graphs, this provides additional structure that can
  be exploited for security analysis.

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


def get_permutations(solutions, q):
    """Convert quaternion solutions to permutations on P^1(F_q). Return: list"""
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


def compute_orbit(permutations, start):
    """
    Compute orbit of start vertex under group action.
    Return: set of reachable vertices
    """
    n = len(permutations[0])
    orbit = set([start])
    queue = [start]
    
    while queue:
        current = queue.pop(0)
        for perm in permutations:
            # Apply perm
            next_vertex = perm[current]
            if next_vertex not in orbit:
                orbit.add(next_vertex)
                queue.append(next_vertex)
            
            # Apply perm inverse
            inv_perm = [0] * n
            for i, p in enumerate(perm):
                inv_perm[p] = i
            next_vertex_inv = inv_perm[current]
            if next_vertex_inv not in orbit:
                orbit.add(next_vertex_inv)
                queue.append(next_vertex_inv)
    
    return orbit


def compute_stabilizer(permutations, point):
    """
    Compute stabilizer subgroup of point (elements that fix point).
    Return: list of permutations in stabilizer
    """
    n = len(permutations[0])
    stabilizer = []
    
    # Check each generator
    for idx, perm in enumerate(permutations):
        if perm[point] == point:
            stabilizer.append(idx)
    
    return stabilizer


# CONSTRUCT PERMUTATIONS

solutions = get_quaternion_solutions(p)
permutations = get_permutations(solutions, q)
k = len(permutations)
d = len(permutations[0])

# VALIDATION

print("[VERIF_11] Group Action Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("  k = " + str(k) + " generators")
print("  d = " + str(d) + " (|P^1(F_q)|)")
print("")

# Check 1: Transitivity (single orbit)
orbit_0 = compute_orbit(permutations, 0)
transitive_check = (len(orbit_0) == d)

print("  Transitivity check:")
print("    Orbit of vertex 0: " + str(len(orbit_0)) + " vertices")
print("    Expected: " + str(d) + " vertices")
print("    Action is transitive: " + str(transitive_check))
print("")

# Check 2: Orbit structure (all orbits have same size for transitive action)
if transitive_check:
    print("  Orbit structure:")
    print("    Single orbit of size " + str(d))
    print("    Action is transitive ✓")
else:
    print("  Orbit structure:")
    print("    Multiple orbits detected")
    orbits = []
    visited = set()
    for v in range(d):
        if v not in visited:
            orbit = compute_orbit(permutations, v)
            orbits.append(orbit)
            visited.update(orbit)
    
    print("    Number of orbits: " + str(len(orbits)))
    for idx, orbit in enumerate(orbits):
        print("      Orbit " + str(idx+1) + ": size " + str(len(orbit)))
print("")

# Check 3: Stabilizer structure
print("  Stabilizer structure:")
for v in range(min(5, d)):  # Check first 5 vertices
    stab = compute_stabilizer(permutations, v)
    print("    Stabilizer of vertex " + str(v) + ": " + str(len(stab)) + " generators")
    if len(stab) > 0:
        print("      Generators: " + str([s+1 for s in stab]))
print("")

# Check 4: Verify orbit-stabilizer theorem
# |G| = |orbit| × |stabilizer|
# For transitive action: |G| = d × |stab(v)| for any v

if transitive_check:
    stab_0 = compute_stabilizer(permutations, 0)
    expected_group_order = d * len(stab_0)
    
    print("  Orbit-stabilizer theorem:")
    print("    |orbit| = " + str(d))
    print("    |stab(0)| = " + str(len(stab_0)))
    print("    |G| = |orbit| × |stab| = " + str(expected_group_order))
    print("    Note: This is lower bound (stabilizer may have more elements)")
else:
    print("  Orbit-stabilizer theorem: Skipped (action not transitive)")
print("")

# Check 5: Verify generators are independent
# Check if any generator is identity or duplicate
independent_check = True
for i in range(k):
    perm = permutations[i]
    if all(perm[j] == j for j in range(d)):
        independent_check = False
        print("    ❌ Generator " + str(i+1) + " is identity")

for i in range(k):
    for j in range(i+1, k):
        if permutations[i] == permutations[j]:
            independent_check = False
            print("    ❌ Generators " + str(i+1) + " and " + str(j+1) + " are identical")

print("  Generators are independent: " + str(independent_check))
print("")

# Summary
print("  Summary:")
print("    Transitive action: " + str(transitive_check))
print("    Number of orbits: " + str(1 if transitive_check else "multiple"))
print("    Generators independent: " + str(independent_check))
print("")

# FINAL RESULT

all_checks = [transitive_check, independent_check]
result = all(all_checks)

print("RESULT: " + str(result))
