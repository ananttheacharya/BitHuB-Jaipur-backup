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

## Phase 2: The CDN Subresource Integrity (SRI) Hash Bug
After replacing `react-katex` with a direct CDN import in `index.html` and custom React wrappers, the production site began displaying raw LaTeX strings exactly as they appeared in the database (e.g., `\text{Can } \sin(\ln x^{2})...`) without crashing or mangling.

**The Cause:** The `katex.min.js` CDN script tag included an `integrity="sha384-..."` attribute, but the hash provided was syntactically invalid/incorrect for version 0.16.9. 
- Modern browsers enforce strict Subresource Integrity (SRI) on production domains. 
- Because the hash didn't match the downloaded file, the browser outright **blocked the script from executing**.
- As a result, `window.katex` was `undefined`. Our React wrapper `InlineMath` elegantly fell back to `<span>{math}</span>` when `window.katex` was missing, which explains why the raw string appeared perfectly intact on the frontend without any Vite mangling!

## Verification & Confirmation Measures
To automate the confirmation of this issue and ensure it never silently fails again, we are implementing a direct verification script in `index.html`.

**Verification Steps:**
1. Open the production site.
2. If `window.katex` fails to load (due to SRI mismatch or network issues), the verification script will immediately inject a highly visible red banner at the bottom right of the screen saying **"KaTeX Failed to Load"**.
This foolproof measure ensures that any future CDN or integrity issues are instantly visible, rather than failing silently into raw text.

## Phase 3: The "Duplicate Text" MathML Bug & The Birth of HaTeX
After fixing the CDN issue, KaTeX successfully loaded and rendered the mathematics beautifully. However, a new bug appeared: every mathematical expression was duplicated, showing the beautifully rendered LaTeX first, followed immediately by a crushed, plain-text version of the math (e.g., `dx2d2y - 3dxdy`).

**The Cause:** By default, KaTeX's `renderToString` outputs both visual HTML and an accessibility block in MathML (`<span class="katex-mathml">`). Normally, the `katex.min.css` file hides this MathML block visually using CSS `clip` and `position: absolute`. However, due to CSS conflicts or loading race conditions, the MathML block became visible on the page, causing the browser to render the raw MathML tags as crushed plain text right below the HTML version.

**The Solution:**
We discarded the basic `InlineMath` and `BlockMath` components and implemented **HaTeX** (The "I Hate Vite" Math Renderer). HaTeX explicitly forces KaTeX to strip out the MathML block by passing `output: 'html'` into the `renderToString` options:
`window.katex.renderToString(math, { throwOnError: false, displayMode: false, output: 'html' })`

This completely eradicated the duplicate plain-text rendering and relied strictly on the HTML output.

## Phase 4: The Final Betrayal (CSS SRI Hash Mismatch)
Just when we thought it was over, HaTeX successfully stripped the MathML block, leaving only the HTML output. However, the math *still* looked like crushed plain text (`-x^2e^x` instead of a properly formatted superscript). 

**The Cause:** The `katex.min.css` file was silently failing to load in production! We had a mismatch in the Subresource Integrity (SRI) hash for the CSS file (`sha384-n8MVd4RsNIU0tAv4ct0nTaAbDJwPJzDEaqSD1odI+WdtXRGWt2kTvGFasHpSy3SV` was required, but we had the official doc's version which jsdelivr had apparently altered slightly).

Without the CSS, the browser ignored all of KaTeX's `.vlist` and `.mord` positional classes, rendering the carefully constructed HTML elements strictly inline as raw text!

**The Final Fix:** We calculated the exact hash directly from the CDN response and corrected it in `index.html`. The CSS now loads successfully, properly formatting the KaTeX HTML spans into elevated, beautiful mathematics.

The pipeline is now truly robust. We have conquered Vite's tree-shaking, bypassed the bundler, survived the CDN integrity checks, stripped the MathML duplicates, and corrected the styling hash.
