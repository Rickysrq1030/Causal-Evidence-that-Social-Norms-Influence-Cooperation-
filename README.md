# Causal Evidence that Social Norms Influence Cooperation
## Simulation Code

All numerical simulations were performed in MATLAB (R2026a). The source code is organized into modular scripts corresponding to the figures presented in the main text and supplementary material.

### Software Requirements and Execution
To ensure reproducibility, the following environment settings are required:

- **Software:** MATLAB R2023b or higher.
- **Function Dependency:** Every simulation script relies on the standalone function `generate_pop_distribution.m`. This file must be located in the same working directory as the scripts.
- **Parallel Computing:** While scripts are written for serial execution, the `iterations` loops can be converted to `parfor` if the Parallel Computing Toolbox is available.

### Script Catalog
The following table describes the MATLAB scripts included in the supplementary repository:

| File Name | Associated Figure | Simulation Goal |
| :--- | :--- | :--- |
| `SM_Figure_1.m` | SM Fig. 1 | Visualizes population distribution types. |
| `SM_Figure_2.m` | SM Fig. 2 | Comparative steady-states for all γ types. |
| `SM_Figure_3.m` | SM Fig. 3 | Sensitivity analysis of Decision Intensity (β). |
| `Main_Figure_1.m` | Main Fig. 1 | Social Payoff (π<sup>social</sup>) parameter sweep. |
| `Main_Figure_2.m` | Main Fig. 2 | Temporal trajectories and convergence paths. |
| `Main_Figure_3.m` | Main Fig. 3 | Basin of attraction and initial state sensitivity. |

*Description of the MATLAB scripts and their corresponding roles in the study.*

### Data Processing Logic
Each script implements a consistent logic flow:

1.  **Initialization:** Invokes `generate_pop_distribution` to create *N* agent-specific thresholds.
2.  **Iterative Simulation:** Executes 3,000 generations across 500 independent iterations.
3.  **Steady-State Extraction:** Calculates the mean of the final 10% of generations (G<sub>2700</sub>–G<sub>3000</sub>) to determine asymptotic behavior.
4.  **Error Estimation:** Computes 95% Confidence Intervals (CI) using the standard deviation across iterations divided by √500.

## Human Experiment Code
