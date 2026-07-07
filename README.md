# PQ Topological

Post-Quantum Cryptography based on Topological Covering Spaces and LPS Ramanujan Graphs.

## What is PQ Topological?

This project implements a post-quantum cryptographic scheme based on **topological covering spaces** and **equivalent partial monodromy problem (EPMP)**. The security relies on the hardness of finding equivalent monodromy representations in covering spaces over graphs with strong expander properties.

Unlike lattice-based or code-based schemes, this approach uses **algebraic topology** and **expander graph theory** to construct cryptographic primitives resistant to quantum attacks.

## Hard Problem: Equivalent Partial Monodromy Problem (EPMP)

The security of this scheme is based on the following computational problem:

**Given:**
- A base graph B (bouquet of k circles)
- A covering space E with degree d
- Partial constraints Γ ⊂ π₁(B) and α ∈ π₁(B)
- Public monodromy representation ρ: π₁(B) → S_d

**Find:**
- An alternative monodromy ρ' ≠ ρ satisfying:
  - ρ'(γ)(0) = 0 for all γ ∈ Γ
  - ρ'(α)(0) = 1

**Hardness Assumption:**
Finding ρ' is computationally infeasible when:
1. The Schreier graph has strong expander properties (Ramanujan graphs)
2. The search space (d!)^k is sufficiently large
3. All constraints are non-trivial (word length ≥ 2)
4. The group action is transitive

This problem is related to the **geodesic problem** in Ramanujan graphs and the **representation problem** in quaternion algebras, both of which have no known polynomial-time algorithms.

## Mathematical Foundation: LPS Ramanujan Graphs

The construction uses **Lubotzky-Phillips-Sarnak (LPS) Ramanujan graphs** to ensure strong expander properties:

**Construction:**
1. Choose primes p, q ≡ 1 (mod 4) with p ≠ q
2. Find quaternion solutions to a² + b² + c² + d² = p
3. Convert to matrices in PGL(2, F_q)
4. Construct permutations on P¹(F_q) via Möbius action
5. Build bipartite double cover Y^{p,q} (simple graph, no self-loops)

**Properties:**
- (p+1)-regular graph
- Optimal spectral gap: |λ₂| ≤ 2√p (Ramanujan bound)
- Diameter: O(log q)
- Rapid mixing: O(log q) steps
- Strong expansion: prevents local search attacks

These properties ensure that SAT solvers and other local search algorithms cannot exploit structural weaknesses.

## Verification Suite

This repository contains 12 verification scripts that rigorously validate all aspects of the construction:

**LPS Construction (verif_01 - verif_06):**
- Parameter validation (primes, congruences)
- Quaternion solutions (norm equation, constraints)
- Matrix conversion (determinant, trace, invertibility)
- Permutation construction (bijections, fixed points)
- X^{p,q} graph (regularity, Ramanujan property)
- Y^{p,q} graph (simple, bipartite, connected, Ramanujan)

**EPMP Instance (verif_07 - verif_09):**
- Instance construction (constraints satisfaction)
- Trivial constraints analysis (all non-trivial)
- Homomorphism verification (ρ is valid group homomorphism)

**Security Properties (verif_10 - verif_12):**
- Expander properties (spectral gap, diameter, mixing time)
- Group action (transitivity, orbit structure)
- Security analysis (search space, attack complexity)

## How to Run

All verifications require **SageMath**. Run each script:

```bash
sage verif_01_parameters.sage
sage verif_02_quaternion_solutions.sage
...
sage verif_12_security_analysis.sage
