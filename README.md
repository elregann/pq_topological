# PQ Topological

Post-Quantum Cryptography based on Topological Covering Spaces and LPS Ramanujan Graphs.

## What is PQ Topological?

This project implements a post-quantum cryptographic scheme based on topological covering spaces and equivalent partial monodromy problem (EPMP). The security relies on the hardness of finding equivalent monodromy representations in covering spaces over graphs with strong expander properties.

Unlike lattice-based or code-based schemes, this approach uses algebraic topology and expander graph theory to construct cryptographic primitives resistant to quantum attacks.

## Hard Problem: Equivalent Partial Monodromy Problem (EPMP)

The security of this scheme is based on the following computational problem:

Given:
- A base graph B (bouquet of k circles)
- A covering space E with degree d
- Partial constraints Gamma subset of pi_1(B) and alpha in pi_1(B)
- Public monodromy representation rho: pi_1(B) -> S_d

Find:
- An alternative monodromy rho' != rho satisfying:
  - rho'(gamma)(0) = 0 for all gamma in Gamma
  - rho'(alpha)(0) = 1

Hardness Assumption:
Finding rho' is computationally infeasible when:
1. The Schreier graph has strong expander properties (Ramanujan graphs)
2. The search space (d!)^k is sufficiently large
3. All constraints are non-trivial (word length >= 2)
4. The group action is transitive

This problem is related to the geodesic problem in Ramanujan graphs and the representation problem in quaternion algebras, both of which have no known polynomial-time algorithms.

## Mathematical Foundation: LPS Ramanujan Graphs

The construction uses Lubotzky-Phillips-Sarnak (LPS) Ramanujan graphs to ensure strong expander properties:

Construction:
1. Choose primes p, q congruent to 1 (mod 4) with p != q
2. Find quaternion solutions to a^2 + b^2 + c^2 + d^2 = p
3. Convert to matrices in PGL(2, F_q)
4. Construct permutations on P^1(F_q) via Mobius action
5. Build bipartite double cover Y^{p,q} (simple graph, no self-loops)

Properties:
- (p+1)-regular graph
- Optimal spectral gap: |lambda_2| <= 2*sqrt(p) (Ramanujan bound)
- Diameter: O(log q)
- Rapid mixing: O(log q) steps
- Strong expansion: prevents local search attacks

These properties ensure that SAT solvers and other local search algorithms cannot exploit structural weaknesses.

## Verification Suite

This repository contains 12 verification scripts that rigorously validate all aspects of the construction:

LPS Construction (verif_01 - verif_06):
- Parameter validation (primes, congruences)
- Quaternion solutions (norm equation, constraints)
- Matrix conversion (determinant, trace, invertibility)
- Permutation construction (bijections, fixed points)
- X^{p,q} graph (regularity, Ramanujan property)
- Y^{p,q} graph (simple, bipartite, connected, Ramanujan)

EPMP Instance (verif_07 - verif_09):
- Instance construction (constraints satisfaction)
- Trivial constraints analysis (all non-trivial)
- Homomorphism verification (rho is valid group homomorphism)

Security Properties (verif_10 - verif_12):
- Expander properties (spectral gap, diameter, mixing time)
- Group action (transitivity, orbit structure)
- Security analysis (search space, attack complexity)

## KEM Implementation

The file `epmp_kem.sage` contains a proof-of-concept Key Encapsulation Mechanism built on top of EPMP. This demonstrates that a KEM can be constructed over the EPMP hard problem, although this implementation is not yet production-ready.

Protocol Overview:

KeyGen (Alice):
- Generate LPS permutations rho from primes p, q
- rho serves as private key
- Public parameters (p, q, k, d) are shared with Bob

Encapsulate (Bob):
- Generate random path P in LPS graph from vertex 0
- Compute intermediate vertices along the path
- Build constraints from path: rho(g_i)(v_{i-1}) = v_i
- Identify trivial constraints (where generator fixes the from-vertex)
- Send only non-trivial constraints + hint + endpoint to Alice
- Hint = SHA-256(path || rho_signature)
- Shared secret = SHA-256(path)

Decapsulate (Alice):
- Recover all possible paths consistent with non-trivial constraints using rho
- Verify hint for each candidate path
- Unique matching path gives shared secret
- Shared secret = SHA-256(path)

Security Mechanism:
- Eve sees only non-trivial constraints, hint, and endpoint
- Trivial constraints (from generators fixing sheet 0) hide information from Eve
- Hint resolves path ambiguity using SHA-256 collision resistance
- Without rho, Eve must solve EPMP to recover the path

Important Notice:
This is a proof-of-concept implementation. While it demonstrates that KEM construction over EPMP is feasible, it has not undergone formal security analysis. The current parameters (p=5, q=13, path_length=8) are suitable for demonstration but not for production use. Formal security reduction, side-channel resistance, and parameter optimization are subjects of ongoing research.

## How to Run

All scripts require SageMath.

Run verification scripts:

    sage verif_01_parameters.sage
    sage verif_02_quaternion_solutions.sage
    ...
    sage verif_12_security_analysis.sage

Each verification script outputs detailed validation results and ends with RESULT: True if all checks pass.

Run KEM demonstration:

    sage epmp_kem.sage

The KEM script demonstrates the complete key exchange between Alice and Bob, ending with RESULT: True if both parties derive the same shared secret.

Configuration:
Parameters p and q are defined at the top of each script. Current defaults: p = 5, q = 13.

To test different parameters, modify the CONFIGURATION section in each file.

## Security Analysis

For parameters p = 5, q = 13:
- Search space: 2^218 (approximately 10^65)
- Effective security: 2^176 bits
- Target security: 128 bits (achieved)
- Security margin: 48 bits above target

The construction provides adequate security margin against brute-force and known algebraic attacks. For higher security, increase p and q.

Attack Resistance:
- Brute force: O(2^218) operations
- Local search: Prevented by expander properties
- Algebraic attacks: No known polynomial-time algorithms for quaternion-based constructions

Note: The KEM implementation introduces additional attack surfaces (path brute force, hint collision) that require separate analysis. The security numbers above apply to the underlying EPMP hard problem, not directly to the KEM construction.

## Implementation Status

Complete and Verified:
- LPS Ramanujan graph construction
- EPMP instance generation
- All mathematical properties validated
- Security analysis of underlying hard problem
- Proof-of-concept KEM implementation

Ongoing Research:
- Formal security reduction for KEM construction
- Parameter optimization for production use
- Empirical hardness testing with SAT solvers
- Comparison with NIST PQC standards
- Side-channel resistance analysis

## References

1. Lubotzky, A., Phillips, R., Sarnak, P. "Ramanujan Graphs." Combinatorica 8(3), 1988.
2. Charles, D.X., Goren, E.Z., Lauter, K.E. "Cryptographic Hash Functions from Expander Graphs." Journal of Cryptology, 2009.

## License

This is a research project. Use at your own risk.

## Contact

For questions or collaboration, please open an issue.
