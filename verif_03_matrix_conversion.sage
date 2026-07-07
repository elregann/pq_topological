"""
VERIF_03: Matrix Conversion Validation for LPS Construction

Purpose:
  Convert quaternion solutions to 2x2 matrices over F_q and validate properties.

Matrix Conversion:
  For quaternion (a, b, c, d), construct matrix:
    M = [[a + bi, c + di],
         [-c + di, a - bi]]
  where i² = -1 in F_q (requires q ≡ 1 mod 4).

Required Properties:
  1. q ≡ 1 (mod 4) - ensures sqrt(-1) exists in F_q
  2. det(M) = p mod q for all matrices
  3. trace(M) = 2a mod q for all matrices
  4. All matrices are invertible (det ≠ 0)
  5. Number of matrices = p + 1

Mathematical Background:
  This is the standard representation of quaternions as 2x2 complex matrices,
  reduced modulo q. The determinant equals the quaternion norm.

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


# GET SOLUTIONS

solutions = get_quaternion_solutions(p)

# CONSTRUCT MATRICES

Fq = GF(q)
i = Fq(-1).sqrt()  # sqrt(-1) in F_q

matrices = []
for sol in solutions:
    a, b, c, d = sol
    a_f, b_f, c_f, d_f = Fq(a), Fq(b), Fq(c), Fq(d)
    
    M = matrix(Fq, 2, 2, [
        a_f + i * b_f,  c_f + i * d_f,
        -c_f + i * d_f, a_f - i * b_f
    ])
    matrices.append((sol, M))

# VALIDATION

print("[VERIF_03] Matrix Conversion Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("")

# Check 1: q ≡ 1 (mod 4)
q_mod_4 = (q % 4 == 1)
print("  q mod 4 = 1: " + str(q_mod_4))

# Check 2: sqrt(-1) exists
sqrt_minus_one_exists = (i * i == Fq(-1))
print("  sqrt(-1) exists in F_q: " + str(sqrt_minus_one_exists))
print("    i = " + str(i))
print("")

# Check 3: Number of matrices = p + 1
num_matrices = len(matrices)
expected_num = p + 1
num_check = (num_matrices == expected_num)
print("  Number of matrices = p + 1: " + str(num_check))
print("    Expected: " + str(expected_num) + ", Actual: " + str(num_matrices))
print("")

# Check 4: All determinants = p mod q
det_check = True
for sol, M in matrices:
    det_M = M.det()
    expected_det = Fq(p)
    if det_M != expected_det:
        det_check = False
        break
print("  All det(M) = p mod q: " + str(det_check))

# Check 5: All traces = 2a mod q
trace_check = True
for sol, M in matrices:
    a = sol[0]
    trace_M = M.trace()
    expected_trace = Fq(2 * a)
    if trace_M != expected_trace:
        trace_check = False
        break
print("  All trace(M) = 2a mod q: " + str(trace_check))

# Check 6: All matrices invertible
invertible_check = True
for sol, M in matrices:
    det_M = M.det()
    if det_M == 0:
        invertible_check = False
        break
print("  All matrices invertible: " + str(invertible_check))

print("")

# Display matrices
print("  Matrices:")
for idx, (sol, M) in enumerate(matrices):
    a, b, c, d = sol
    det_M = M.det()
    trace_M = M.trace()
    print("    " + str(idx+1) + ". (" + str(a) + ", " + str(b) + ", " + str(c) + ", " + str(d) + ")")
    print("       det = " + str(det_M) + ", trace = " + str(trace_M))

print("")

# FINAL RESULT

all_checks = [q_mod_4, sqrt_minus_one_exists, num_check, det_check, 
              trace_check, invertible_check]
result = all(all_checks)

print("RESULT: " + str(result))
