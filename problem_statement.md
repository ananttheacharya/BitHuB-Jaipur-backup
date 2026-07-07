# Problem Statement: Production LaTeX Rendering Failure

## The Core Issue
In the production deployment (built via Vite/Rollup), all mathematical questions containing LaTeX commands are mangled. For example, the database text:
\text{Solve by variation of Parameter } \frac{d^{2}y}{dx^{2}}+9y=\tan 3x.
is rendered in production as:
\textSolvebyvariationofParameter\fracd^2ydx^2 + 9y = \tan3x.

## Root Cause Analysis
This is **not** a database escaping issue, nor is it a backend parsing issue. The backend correctly serves the full LaTeX string with all curly braces intact.

The problem lies entirely in the **Vite (Rollup) production build step**. 
The project uses the eact-katex library, which internally imports katex. When Rollup bundles katex for production, its aggressive tree-shaking algorithm incorrectly assumes that KaTeX's macro definitions (like \text, \frac, \sin, \cos) have no side-effects and **strips them completely from the final JavaScript bundle**.

Because these macros are missing at runtime in production:
1. KaTeX fails to recognize \text, \frac, etc., and (due to throwOnError: false) falls back to printing the raw text \text, \frac.
2. Because the renderer is still in "Math Mode", it strips all curly braces {} (which are math-grouping characters) and ignores all spaces.
3. This perfectly explains why \text{Solve by variation of Parameter } becomes \textSolvebyvariationofParameter.

## Why Previous Fixes Failed
We attempted to fix this by adding a resolve.alias in vite.config.js to force Vite to use the pre-built UMD bundle of KaTeX. However, because eact-katex is a pre-compiled CommonJS module, Vite's alias resolution during the esbuild pre-bundling and Rollup phases failed to properly override the internal require("katex") calls inside eact-katex. The final bundle still contained the broken, tree-shaken version of KaTeX.

## The Objective
We need a **fool-proof, robust workaround** that completely sidesteps Vite's module resolution and tree-shaking for KaTeX, ensuring that all mathematical macros are 100% available in the production build.
