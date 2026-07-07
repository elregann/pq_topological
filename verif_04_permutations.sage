"""
VERIF_04: Permutation Construction Validation for LPS Construction

Purpose:
  Convert matrices to permutations on P^1(F_q) and validate properties.

Permutation Construction:
  For matrix M = [[A, B], [C, D]] in PGL(2, F_q), define permutation:
    π_M(x) = (Ax + B) / (Cx + D)
  on P^1(F_q) = F_q ∪ {∞}.

Required Properties:
  1. Each permutation is a bijection (valid permutation)
  2. Number of permutations = p + 1
  3. Fixed points correctly computed
  4. Identify generators that fix sheet 0

Mathematical Background:
  This is the Möbius action of PGL(2, F_q) on the projective line.
  Fixed points satisfy Cx² + (D-A)x - B = 0 (for C ≠ 0).
  For C = 0 (diagonal matrices), fixed points satisfy (A-D)x + B = 0.

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
    """Convert quaternion solutions to matrices. Return: list of (sol, M)"""
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
        matrices.append((sol, M))
    
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


def get_fixed_points(M, Fq):
    """Find fixed points of M on P^1(F_q). Return: list"""
    A, B, C, D = M[0, 0], M[0, 1], M[1, 0], M[1, 1]
    fixed_points = []
    
    if C == 0:
        # Diagonal case: M · inf = inf (fixed)
        fixed_points.append('inf')
        
        # Finite fixed points: (A-D)x + B = 0
        if A != D:
            x = -B / (A - D)
            fixed_points.append(x)
        # else: A = D, check if B = 0 (identity case, shouldn't happen for LPS)
    else:
        # Quadratic case: Cx² + (D-A)x - B = 0
        disc = (D - A)**2 + 4 * B * C
        
        if disc == 0:
            x = -(D - A) / (2 * C)
            fixed_points.append(x)
        elif disc.is_square():
            sqrt_disc = disc.sqrt()
            x1 = (-(D - A) + sqrt_disc) / (2 * C)
            x2 = (-(D - A) - sqrt_disc) / (2 * C)
            fixed_points.append(x1)
            fixed_points.append(x2)
    
    return fixed_points


# CONSTRUCT PERMUTATIONS

solutions = get_quaternion_solutions(p)
matrices = get_matrices(solutions, q)

Fq = GF(q)
P1 = list(range(q)) + ['inf']  # P^1(F_q)
n = q + 1

permutations = []
for sol, M in matrices:
    perm = []
    for x in P1:
        y = mobius_action(M, x)
        y_idx = P1.index(y)
        perm.append(y_idx)
    
    fixed_pts = get_fixed_points(M, Fq)
    fixed_pts_idx = [P1.index(fp) for fp in fixed_pts]
    
    permutations.append((sol, perm, fixed_pts_idx))

# VALIDATION

print("[VERIF_04] Permutation Construction Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("")

# Check 1: Number of permutations = p + 1
num_perms = len(permutations)
expected_num = p + 1
num_check = (num_perms == expected_num)
print("  Number of permutations = p + 1: " + str(num_check))
print("    Expected: " + str(expected_num) + ", Actual: " + str(num_perms))
print("")

# Check 2: All permutations are bijections
bijection_check = True
for sol, perm, fixed_pts in permutations:
    if len(set(perm)) != n:
        bijection_check = False
        break
print("  All permutations are bijections: " + str(bijection_check))

# Check 3: Fixed points correctly computed
fixed_points_check = True
for sol, perm, fixed_pts in permutations:
    for fp in fixed_pts:
        if perm[fp] != fp:
            fixed_points_check = False
            break
print("  Fixed points correctly computed: " + str(fixed_points_check))

# Check 4: Verify fixed points by direct computation
direct_check = True
for sol, perm, fixed_pts in permutations:
    # Compute all fixed points by brute force
    actual_fixed = [i for i in range(n) if perm[i] == i]
    if set(actual_fixed) != set(fixed_pts):
        direct_check = False
        print("    Mismatch for " + str(sol) + ": computed=" + str(fixed_pts) + ", actual=" + str(actual_fixed))
        break
print("  Fixed points verified by direct computation: " + str(direct_check))

# Check 5: Identify generators fixing sheet 0
generators_fixing_0 = []
for idx, (sol, perm, fixed_pts) in enumerate(permutations):
    if 0 in fixed_pts:
        generators_fixing_0.append(idx + 1)

print("  Generators fixing sheet 0: " + str(generators_fixing_0))
print("")

# Display permutations
print("  Permutations:")
for idx, (sol, perm, fixed_pts) in enumerate(permutations):
    a, b, c, d = sol
    print("    " + str(idx+1) + ". (" + str(a) + ", " + str(b) + ", " + str(c) + ", " + str(d) + ")")
    print("       Fixed points: " + str(fixed_pts))
    print("       Fixes sheet 0: " + str(0 in fixed_pts))

print("")

# FINAL RESULT

all_checks = [num_check, bijection_check, fixed_points_check, direct_check]
result = all(all_checks)

print("RESULT: " + str(result))
