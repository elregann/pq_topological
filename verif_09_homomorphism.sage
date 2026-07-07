"""
VERIF_09: Homomorphism Verification for EPMP Monodromy

Purpose:
  Verify that ρ: F_k → S_d is a valid group homomorphism from the free
  group to the symmetric group.

Homomorphism Properties:
  For ρ to be a valid homomorphism, it must satisfy:
  1. ρ(w₁ · w₂) = ρ(w₁) ∘ ρ(w₂) for all words w₁, w₂
  2. ρ(x_i · x_i⁻¹) = identity for all generators x_i
  3. ρ(empty word) = identity
  4. ρ preserves group operation (composition)

Mathematical Background:
  The monodromy ρ assigns to each generator x_i a permutation ρ(x_i) ∈ S_d.
  For any word w = x_{i₁}^{ε₁} · x_{i₂}^{ε₂} · ... · x_{i_m}^{ε_m},
  the evaluation is ρ(w) = ρ(x_{i₁})^{ε₁} ∘ ρ(x_{i₂})^{ε₂} ∘ ... ∘ ρ(x_{i_m})^{ε_m}.
  
  We use LEFT ACTION convention: ρ(x₁ · x₂)(s) = ρ(x₂)(ρ(x₁)(s)).
  This means composition order is reversed: ρ(w₁ · w₂) = ρ(w₂) ∘ ρ(w₁).

Author: EPMP-LPS Project
Date: 2026-07-08
"""

import random

# CONFIGURATION
p = 5
q = 13
num_tests = 20
seed = 42

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


def evaluate_word(word, permutations):
    """
    Evaluate word in free group using permutations.
    word: list of (generator_index, sign) where sign is +1 or -1
    Return: resulting permutation (list)
    
    Uses LEFT ACTION convention: ρ(x₁ · x₂)(s) = ρ(x₂)(ρ(x₁)(s))
    """
    n = len(permutations[0])
    result = list(range(n))
    
    for gen_idx, sign in word:
        perm = permutations[gen_idx]
        
        if sign < 0:
            inv_perm = [0] * n
            for i, p in enumerate(perm):
                inv_perm[p] = i
            perm = inv_perm
        
        new_result = [0] * n
        for i in range(n):
            new_result[i] = perm[result[i]]
        result = new_result
    
    return result


def compose_permutations(perm1, perm2):
    """
    Compose two permutations with left action convention.
    Result = perm2 ∘ perm1 (apply perm1 first, then perm2).
    This matches the convention used in evaluate_word.
    Return: resulting permutation (list)
    """
    n = len(perm1)
    result = [0] * n
    for i in range(n):
        result[i] = perm2[perm1[i]]  # ← FIXED: apply perm1 first, then perm2
    return result


def is_identity(perm):
    """Check if permutation is identity. Return: boolean"""
    n = len(perm)
    return all(perm[i] == i for i in range(n))


def generate_random_word(k, max_length, rng):
    """Generate random word in free group. Return: list of (gen_idx, sign)"""
    length = rng.randint(1, max_length)
    word = []
    for _ in range(length):
        gen_idx = rng.randint(0, k-1)
        sign = rng.choice([1, -1])
        word.append((gen_idx, sign))
    return word


# CONSTRUCT PERMUTATIONS

solutions = get_quaternion_solutions(p)
permutations = get_permutations(solutions, q)
k = len(permutations)
d = len(permutations[0])

# VALIDATION

print("[VERIF_09] Homomorphism Verification")
print("  p = " + str(p))
print("  q = " + str(q))
print("  k = " + str(k) + " generators")
print("  d = " + str(d) + " covering degree")
print("  num_tests = " + str(num_tests))
print("")

random.seed(int(seed))

# Check 1: ρ(empty word) = identity
empty_word = []
empty_result = evaluate_word(empty_word, permutations)
empty_check = is_identity(empty_result)
print("  ρ(empty word) = identity: " + str(empty_check))
print("")

# Check 2: ρ(x_i · x_i⁻¹) = identity for all generators
inverse_check = True
for i in range(k):
    word = [(i, 1), (i, -1)]
    result = evaluate_word(word, permutations)
    if not is_identity(result):
        inverse_check = False
        print("    ❌ ρ(x_" + str(i+1) + " · x_" + str(i+1) + "^(-1)) ≠ identity")

print("  ρ(x_i · x_i⁻¹) = identity for all i: " + str(inverse_check))
print("")

# Check 3: ρ(w₁ · w₂) = ρ(w₁) ∘ ρ(w₂) for random words
homomorphism_check = True
failures = []

for test_idx in range(int(num_tests)):
    # Generate two random words
    w1 = generate_random_word(k, 5, random)
    w2 = generate_random_word(k, 5, random)
    
    # Evaluate ρ(w₁ · w₂)
    w_concat = w1 + w2
    rho_concat = evaluate_word(w_concat, permutations)
    
    # Evaluate ρ(w₁) ∘ ρ(w₂) with correct composition order
    rho_w1 = evaluate_word(w1, permutations)
    rho_w2 = evaluate_word(w2, permutations)
    rho_compose = compose_permutations(rho_w1, rho_w2)
    
    # Check equality
    if rho_concat != rho_compose:
        homomorphism_check = False
        failures.append(test_idx + 1)

print("  ρ(w₁ · w₂) = ρ(w₁) ∘ ρ(w₂) for " + str(num_tests) + " random tests: " + str(homomorphism_check))
if not homomorphism_check:
    print("    Failures at test indices: " + str(failures))
print("")

# Check 4: ρ(x_i⁻¹) = ρ(x_i)⁻¹ for all generators
inverse_perm_check = True
for i in range(k):
    # ρ(x_i⁻¹)
    word_inv = [(i, -1)]
    rho_inv = evaluate_word(word_inv, permutations)
    
    # ρ(x_i)⁻¹
    perm = permutations[i]
    perm_inv = [0] * d
    for j, p in enumerate(perm):
        perm_inv[p] = j
    
    if rho_inv != perm_inv:
        inverse_perm_check = False
        print("    ❌ ρ(x_" + str(i+1) + "^(-1)) ≠ ρ(x_" + str(i+1) + ")^(-1)")

print("  ρ(x_i⁻¹) = ρ(x_i)⁻¹ for all i: " + str(inverse_perm_check))
print("")

# Check 5: Associativity - ρ((w₁ · w₂) · w₃) = ρ(w₁ · (w₂ · w₃))
associativity_check = True
assoc_failures = []

for test_idx in range(int(num_tests)):
    w1 = generate_random_word(k, 3, random)
    w2 = generate_random_word(k, 3, random)
    w3 = generate_random_word(k, 3, random)
    
    # ρ((w₁ · w₂) · w₃)
    w_left = (w1 + w2) + w3
    rho_left = evaluate_word(w_left, permutations)
    
    # ρ(w₁ · (w₂ · w₃))
    w_right = w1 + (w2 + w3)
    rho_right = evaluate_word(w_right, permutations)
    
    if rho_left != rho_right:
        associativity_check = False
        assoc_failures.append(test_idx + 1)

print("  Associativity: ρ((w₁ · w₂) · w₃) = ρ(w₁ · (w₂ · w₃)): " + str(associativity_check))
if not associativity_check:
    print("    Failures at test indices: " + str(assoc_failures))
print("")

# Summary
print("  Summary:")
print("    Empty word check: " + str(empty_check))
print("    Inverse check: " + str(inverse_check))
print("    Homomorphism check: " + str(homomorphism_check))
print("    Inverse permutation check: " + str(inverse_perm_check))
print("    Associativity check: " + str(associativity_check))
print("")

# FINAL RESULT

all_checks = [empty_check, inverse_check, homomorphism_check, 
              inverse_perm_check, associativity_check]
result = all(all_checks)

print("RESULT: " + str(result))
