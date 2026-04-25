# Sandcastle Research

## Project Summary
Sandcastle by Matt Pocock is an interactive playground/sandbox for TypeScript and React patterns. It provides a live coding environment where users can write, edit, and see results of TypeScript/React code in real-time, with full type checking and instant preview. The project focuses on teaching and experimenting with TypeScript idioms, React hooks, and other frontend patterns through runnable examples that can be shared via URL.

## Sandbox Patterns
- **Architecture**: Browser-based sandbox utilizing an iframe for isolation. Code is transpiled and bundled on the fly using esbuild (or similar) in a Web Worker to avoid blocking the UI. The resulting bundle is injected into the iframe, ensuring the host page remains unaffected by user code.
- **Safety**: Execution happens in a sandboxed iframe with restrictive CSP and the `sandbox` attribute, limiting access to parent window, network (unless explicitly allowed), and other sensitive APIs. Errors are caught and displayed without crashing the environment.
- **Evaluation**: On each code change, the code is type-checked using the TypeScript compiler service running in a Web Worker, providing immediate diagnostics. After a brief debounce, the code is bundled and the iframe is refreshed (or hot-reloaded if supported).
- **State Management**: Sandcastle maintains the code state in memory and persists via URL encoding, enabling snippet sharing without a backend.

## Code Snippet Sharing Patterns
- Snippets are encoded (typically base64 or LZString) and appended to the URL hash, making each snippet a shareable link.
- The UI includes a "Share" button that copies the current URL to clipboard.
- A gallery of curated examples serves as a starting point; each can be forked into a new sandbox.
- No authentication required; sharing is link-based, emphasizing simplicity.

## Live-Editing + Type Checking Integration
- **Editor**: Monaco Editor (VS Code's editor) with TypeScript syntax highlighting and IntelliSense.
- **Type Checking**: The TypeScript language service runs in a Web Worker, processing the code and returning diagnostics (errors/warnings) as you type. These are displayed inline (squiggles) and in a Problems panel.
- **Live Preview**: The preview pane updates automatically after changes, using a fast bundler (esbuild) and iframe reload. Some implementations may support React Fast Refresh for state preservation.
- **Debouncing**: To avoid excessive recompilation, changes are batched (typically 500-1000ms delay).

## Example-Driven Documentation Approach
- Documentation is delivered as interactive examples rather than static text. Each concept (e.g., "useReducer", "async/await") has a corresponding live sandbox pre-populated with a minimal demonstration.
- Users can edit the example to experiment, reinforcing learning.
- Examples are organized by category (React, TypeScript, etc.) and can be browsed.
- This pattern reduces the need for lengthy explanations; readers can see code in action immediately.

## Hermes Applicability
**Dev Tool or Production?**  
A Sandcastle-style REPL would be primarily a **development and demonstration tool** for Hermes, though it could also be embedded in production documentation or onboarding flows.

- **Provider Testing**: Providers could use a sandbox to test Hermes API calls, experiment with prompt patterns, or validate tool configurations without setting up a full local environment. This accelerates development and debugging.
- **Demo Environments**: For sales or technical demos, a live playground allows prospects to interact with Hermes directly (e.g., try sample queries, see tool responses) in a controlled sandbox, increasing engagement.
- **Onboarding Friction**: New users often struggle with abstract documentation. Interactive examples let them try Hermes immediately, seeing real outputs. This hands-on approach reduces the learning curve and improves retention.

**Recommendation**: Hermes should adopt a Sandcastle-like component for its developer portal and internal testing suites. A dedicated "Hermes Playground" could become a central resource for both internal QA and external evangelism.

## Implementation Idea
- **Tech Stack**: Use Monaco Editor + TypeScript language service (via `monaco-typescript` or `ts-loader`) + esbuild (via Web Worker) + iframe sandbox. Could leverage existing open-source sandbox frameworks (like `sandpack` from CodeSandbox) as a base to accelerate development.
- **Integration**: Create a React component that accepts initial code (or loads from a URL) and provides live preview. For Hermes-specific demos, pre-load snippets that call the Hermes API (using a mock server or a safe demo endpoint).
- **Deployment**: Host as a static page (client-side only) to simplify scaling. Sharing via URL hash enables easy linking.
- **Enhanced Features**: Add support for Node.js built-ins simulation, environment variables, and network request mocking to cover Hermes use cases.
