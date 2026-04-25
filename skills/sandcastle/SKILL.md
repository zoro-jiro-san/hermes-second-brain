---
name: "Sandcastle: Live Code Sandbox & Interactive Learning"
description: "Skills and patterns extracted from Sandcastle research: browser-based code sandboxing, live editing with type checking, and example-driven documentation."
trigger: "when building developer tools, REPLs, interactive coding environments, or example-based learning systems"
---

# Sandcastle: Live Code Sandbox Patterns

## Overview
This skill captures patterns from **Sandcastle** by Matt Pocock — an interactive TypeScript/React playground that provides live coding, instant type-checking, and real-time preview in a sandboxed environment. The focus is on safe, browser-based code execution, example-driven documentation, and shareable snippets via URL encoding.

## What It Does
Provides a framework for:
- **Browser-based sandbox**: iframe isolation with CSP and `sandbox` attribute
- **Live transpilation**: esbuild (or similar) bundling in a Web Worker to avoid UI blocking
- **Type checking**: TypeScript compiler service running in background for inline diagnostics
- **State persistence**: URL-encoded snippets for sharing without backend
- **Example galleries**: Curated, forkable templates to jumpstart learning

## When to Use
- Building developer playgrounds or API testing tools
- Creating interactive tutorials and example-driven documentation
- Prototyping code snippets in a safe, isolated environment
- Enabling users to experiment with APIs without local setup
- Embedding runnable code examples in docs or onboarding flows

## Setup
Read the full research at: `/home/tokisaki/work/research-swarm/outputs/research_sandcastle.md`

## Implementation Steps
1. Choose tech stack: Monaco Editor + TypeScript language service + esbuild (Web Worker) + sandboxed iframe
   - Alternatively, use `@sandpack/react` from CodeSandbox as a base to accelerate
2. Create a sandbox component that:
   - Accepts initial code via props or URL hash
   - Debounces changes (500-1000ms) before re-compilation
   - Displays inline diagnostics (squiggles, Problems panel)
   - Refreshes iframe with bundle output; support Hot Module Replacement if possible
3. Implement snippet encoding (base64 or LZString) and URL hash sharing
4. Add a gallery of curated examples by category (React hooks, TypeScript idioms, etc.)
5. For Hermes-specific use: pre-load snippets that call the Hermes API via mock server or safe demo endpoint
6. Deploy as a static client-side page; optionally add server-side Node.js simulation if needed

## Key Patterns Extracted
### Architecture
- **Editor**: Monaco Editor (VS Code) with syntax highlighting and IntelliSense
- **Type checking**: TypeScript language service in Web Worker; returns diagnostics as you type
- **Bundling**: esbuild (fast) in Web Worker; bundle injected into iframe
- **Sandbox**: iframe with restrictive CSP and `sandbox` attribute; prevents parent access, limits network
- **Debouncing**: Batch changes to avoid excessive recompilation
- **Persistence**: URL hash encoding; no auth required; link-based sharing

### Safety
- Execution confined to sandboxed iframe; host unaffected by user code
- Errors caught and displayed without crashing environment
- CSP limits access to sensitive APIs

### Example-Driven Documentation
- Each concept has a live pre-populated sandbox
- Users edit to experiment; galleries browsable by category
- Reduces need for lengthy explanations; immediate feedback

## Pitfalls
- Be mindful of bundle size limits in iframe; split large apps
- TypeScript worker may lag on very large files; implement incremental parsing
- Cross-origin restrictions if loading external resources; configure CSP carefully
- URL length limits for snippet encoding; consider server-side storage fallback for very large snippets
- Ensure proper cleanup of Web Workers and iframe listeners on unmount to prevent memory leaks

## References
- Research: `research_sandcastle.md`
- Sandpack: https://github.com/codesandbox/sandpack
- Monaco Editor: https://microsoft.github.io/monaco-editor/
