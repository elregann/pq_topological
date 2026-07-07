"""
VERIF_07: EPMP Instance Construction Validation

Purpose:
  Construct an EPMP (Equivalent Partial Monodromy Problem) instance using
  LPS permutations and validate that all constraints are satisfied.

EPMP Instance:
  Secret: monodromy ρ: F_k → S_d (homomorphism from free group)
  Public: (Γ, α) where:
    - Γ ⊂ F_k: set of words satisfying ρ(γ)(0) = 0
    - α ∈ F_k: word satisfying ρ(α)(0) = 1
  Hard problem: Find ρ' ≠ ρ satisfying all constraints.

Required Properties:
  1. All γ ∈ Γ satisfy ρ(γ)(0) = 0
  2. α satisfies ρ(α)(0) = 1
  3. All words in Γ and α have specified word length
  4. No duplicate words in Γ
  5. ρ is a valid homomorphism (each generator is a permutation)

Mathematical Background:
  The EPMP is defined on a covering space with monodromy ρ. The constraints
  Γ encode cycles in the base graph that lift to cycles at sheet 0. The
  constraint α encodes a path from sheet 0 to sheet 1.

Author: EPMP-LPS Project
Date: 2026-07-08
"""

import random

# CONFIGURATION
p = 5
q = 13
num_gamma = 10
word_length = 8
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
        
        # Convert matrix to permutation
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
    """
    n = len(permutations[0])
    result = list(range(n))  # identity
    
    for gen_idx, sign in word:
        perm = permutations[gen_idx]
        
        if sign < 0:
            # Compute inverse permutation
            inv_perm = [0] * n
            for i, p in enumerate(perm):
                inv_perm[p] = i
            perm = inv_perm
        
        # Compose: result = perm ∘ result
        new_result = [0] * n
        for i in range(n):
            new_result[i] = perm[result[i]]
        result = new_result
    
    return result


def generate_gamma_alpha(permutations, k, num_gamma, word_length, seed):
    """
    Generate Γ (words evaluating to 0) and α (word evaluating to 1).
    Return: (Gamma, Alpha)
    """
    random.seed(int(seed))
    
    Gamma = []
    attempts = 0
    max_attempts = 100000
    
    while len(Gamma) < int(num_gamma) and attempts < max_attempts:
        attempts += 1
        word = []
        for _ in range(int(word_length)):
            gen_idx = int(random.randint(0, k-1))
            sign = int(random.choice([1, -1]))
            word.append((gen_idx, sign))
        
        result = evaluate_word(word, permutations)
        if result[0] == 0 and word not in Gamma:
            Gamma.append(word)
    
    Alpha = None
    attempts = 0
    while Alpha is None and attempts < max_attempts:
        attempts += 1
        word = []
        for _ in range(int(word_length)):
            gen_idx = int(random.randint(0, k-1))
            sign = int(random.choice([1, -1]))
            word.append((gen_idx, sign))
        
        result = evaluate_word(word, permutations)
        if result[0] == 1:
            Alpha = word
    
    return Gamma, Alpha


# CONSTRUCT EPMP INSTANCE

solutions = get_quaternion_solutions(p)
permutations = get_permutations(solutions, q)
k = len(permutations)

Gamma, Alpha = generate_gamma_alpha(permutations, k, num_gamma, word_length, seed)

# VALIDATION

print("[VERIF_07] EPMP Instance Construction Validation")
print("  p = " + str(p))
print("  q = " + str(q))
print("  k = " + str(k) + " generators")
print("  d = " + str(len(permutations[0])) + " covering degree")
print("  |Γ| = " + str(len(Gamma)))
print("  word length = " + str(word_length))
print("")

# Check 1: Γ has correct size
gamma_size_check = (len(Gamma) == num_gamma)
print("  |Γ| = num_gamma: " + str(gamma_size_check))
print("    Expected: " + str(num_gamma) + ", Actual: " + str(len(Gamma)))
print("")

# Check 2: α exists
alpha_exists_check = (Alpha is not None)
print("  α exists: " + str(alpha_exists_check))
print("")

# Check 3: All γ ∈ Γ satisfy ρ(γ)(0) = 0
gamma_constraints_check = True
gamma_failures = []
for idx, word in enumerate(Gamma):
    result = evaluate_word(word, permutations)
    if result[0] != 0:
        gamma_constraints_check = False
        gamma_failures.append(idx)

print("  All γ ∈ Γ satisfy ρ(γ)(0) = 0: " + str(gamma_constraints_check))
if not gamma_constraints_check:
    print("    Failures at indices: " + str(gamma_failures))
print("")

# Check 4: α satisfies ρ(α)(0) = 1
if Alpha is not None:
    alpha_result = evaluate_word(Alpha, permutations)
    alpha_constraint_check = (alpha_result[0] == 1)
    print("  α satisfies ρ(α)(0) = 1: " + str(alpha_constraint_check))
    print("    ρ(α)(0) = " + str(alpha_result[0]))
else:
    alpha_constraint_check = False
    print("  α satisfies ρ(α)(0) = 1: False (α not generated)")
print("")

# Check 5: All words have correct length
word_length_check = True
for word in Gamma + [Alpha]:
    if len(word) != word_length:
        word_length_check = False
        break

print("  All words have length " + str(word_length) + ": " + str(word_length_check))
print("")

# Check 6: No duplicates in Γ
no_duplicates_check = (len(Gamma) == len(set(tuple(w) for w in Gamma)))
print("  No duplicates in Γ: " + str(no_duplicates_check))
print("")

# Check 7: Each generator is a valid permutation
permutation_check = True
d = len(permutations[0])
for idx, perm in enumerate(permutations):
    if len(set(perm)) != d:
        permutation_check = False
        break

print("  Each generator is a valid permutation: " + str(permutation_check))
print("")

# Display sample words
print("  Sample Γ words (first 3):")
for idx in range(min(3, len(Gamma))):
    word = Gamma[idx]
    result = evaluate_word(word, permutations)
    word_str = " · ".join(["x" + str(g+1) + ("^(-1)" if s < 0 else "") for g, s in word])
    print("    γ_" + str(idx+1) + ": " + word_str)
    print("       ρ(γ_" + str(idx+1) + ")(0) = " + str(result[0]))

if Alpha is not None:
    print("")
    print("  α word:")
    word_str = " · ".join(["x" + str(g+1) + ("^(-1)" if s < 0 else "") for g, s in Alpha])
    print("    α: " + word_str)
    print("       ρ(α)(0) = " + str(evaluate_word(Alpha, permutations)[0]))

print("")

# FINAL RESULT

all_checks = [gamma_size_check, alpha_exists_check, gamma_constraints_check,
              alpha_constraint_check, word_length_check, no_duplicates_check,
              permutation_check]
result = all(all_checks)

print("RESULT: " + str(result))
