"""
VERIF_01: Parameter Validation for LPS Ramanujan Graph Construction

Purpose:
  Validate that parameters p and q satisfy requirements for LPS construction.

LPS Construction Requirements:
  1. p and q must be prime numbers
  2. p ≡ 1 (mod 4)
  3. q ≡ 1 (mod 4)
  4. p ≠ q

Reference:
  Lubotzky, Phillips, Sarnak. "Ramanujan Graphs." Combinatorica 8(3), 1988.

Author: EPMP-LPS Project
Date: 2026-07-08
"""

# CONFIGURATION
# Change p and q values here to test different parameters
p = 5
q = 13

# VALIDATION FUNCTIONS

def is_prime_check(n):
    """Check if n is prime. Return: boolean"""
    n = int(n)
    if n < 2:
        return False
    if n == 2:
        return True
    if n % 2 == 0:
        return False
    for i in range(3, int(n**0.5) + 1, 2):
        if n % i == 0:
            return False
    return True


def mod_check(n, m):
    """Check if n ≡ 1 (mod m). Return: boolean"""
    return int(n) % int(m) == 1


def neq_check(a, b):
    """Check if a ≠ b. Return: boolean"""
    return int(a) != int(b)


# EXECUTION

print("[VERIF_01] Parameter Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("")

# Check 1: p is prime
p_is_prime = is_prime_check(p)
print("  p is prime: " + str(p_is_prime))

# Check 2: q is prime
q_is_prime = is_prime_check(q)
print("  q is prime: " + str(q_is_prime))

# Check 3: p ≡ 1 (mod 4)
p_mod_4 = mod_check(p, 4)
print("  p mod 4 = 1: " + str(p_mod_4))

# Check 4: q ≡ 1 (mod 4)
q_mod_4 = mod_check(q, 4)
print("  q mod 4 = 1: " + str(q_mod_4))

# Check 5: p ≠ q
p_neq_q = neq_check(p, q)
print("  p != q: " + str(p_neq_q))

print("")

# FINAL RESULT

all_checks = [p_is_prime, q_is_prime, p_mod_4, q_mod_4, p_neq_q]
result = all(all_checks)

print("RESULT: " + str(result))
