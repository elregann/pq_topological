"""
VERIF_02: Quaternion Solutions Validation for LPS Construction

Purpose:
  Find and validate all quaternion solutions to a² + b² + c² + d² = p
  with LPS constraints.

LPS Quaternion Requirements:
  1. a² + b² + c² + d² = p
  2. a > 0 (positive)
  3. a is odd
  4. b, c, d are even
  5. Total count of solutions = p + 1

Mathematical Background:
  These solutions correspond to quaternions of norm p in the Hurwitz order.
  The constraint a > 0, a odd, b,c,d even ensures unique representation
  modulo units.

Reference:
  Lubotzky, Phillips, Sarnak. "Ramanujan Graphs." Combinatorica 8(3), 1988.

Author: EPMP-LPS Project
Date: 2026-07-08
"""

# CONFIGURATION
p = 5

# HELPER FUNCTIONS

def even_numbers_up_to(N):
    """Generate even numbers from -N to N. Return: list"""
    N = int(N)
    if N % 2 == 0:
        return list(range(-N, N+1, 2))
    else:
        return list(range(-(N-1), N, 2))


# FIND SOLUTIONS

solutions = []
max_val = int(p**0.5)

# Iterate a (positive, odd)
for a in range(1, max_val + 1, 2):
    # Iterate b, c, d (even)
    for b in even_numbers_up_to(max_val):
        for c in even_numbers_up_to(max_val):
            for d in even_numbers_up_to(max_val):
                if a*a + b*b + c*c + d*d == p:
                    solutions.append((a, b, c, d))

# VALIDATION

print("[VERIF_02] Quaternion Solutions Validation")
print("  p = " + str(p))
print("")

# Check 1: Count = p + 1
expected_count = p + 1
actual_count = len(solutions)
count_check = (actual_count == expected_count)
print("  Solution count = p + 1: " + str(count_check))
print("    Expected: " + str(expected_count) + ", Actual: " + str(actual_count))
print("")

# Check 2: All solutions satisfy a² + b² + c² + d² = p
norm_check = True
for sol in solutions:
    a, b, c, d = sol
    if a*a + b*b + c*c + d*d != p:
        norm_check = False
        break
print("  All solutions satisfy a²+b²+c²+d²=p: " + str(norm_check))

# Check 3: All a > 0
a_positive_check = all(sol[0] > 0 for sol in solutions)
print("  All a > 0: " + str(a_positive_check))

# Check 4: All a odd
a_odd_check = all(sol[0] % 2 == 1 for sol in solutions)
print("  All a odd: " + str(a_odd_check))

# Check 5: All b, c, d even
bcd_even_check = all(sol[1] % 2 == 0 and sol[2] % 2 == 0 and sol[3] % 2 == 0 
                     for sol in solutions)
print("  All b, c, d even: " + str(bcd_even_check))

# Check 6: All solutions unique
unique_check = (len(solutions) == len(set(solutions)))
print("  All solutions unique: " + str(unique_check))

print("")

# Display solutions
print("  Solutions found:")
for i, sol in enumerate(solutions):
    a, b, c, d = sol
    print("    " + str(i+1) + ". (" + str(a) + ", " + str(b) + ", " + str(c) + ", " + str(d) + ")")

print("")

# FINAL RESULT

all_checks = [count_check, norm_check, a_positive_check, a_odd_check, 
              bcd_even_check, unique_check]
result = all(all_checks)

print("RESULT: " + str(result))
