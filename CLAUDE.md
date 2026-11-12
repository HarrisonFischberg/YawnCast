## Model Routing and Sub-Agents

The main session is the orchestrator. It plans, makes judgment calls, edits small things itself, and merges results. Sub-agents live in `.claude/agents/`.

| Work | Agent | Model |
|---|---|---|
| Find files, search code, read logs/test output, summarize | `scout` | Haiku 5.5 |
| Well-scoped builds: bug fixes, features against a clear spec | `builder` | Sonnet 5.5 |
| Hard builds: migrations, performance, concurrency, crypto, under-specified work | `senior-builder` | Opus 5.5 |
| Independent check of any non-trivial code change | `reviewer` | Opus 5.5 |

- Delegate only when it pays: the work is parallel, read-heavy, or bigger than one context. A small task or a single chain of dependent steps stays inline.
- Every builder brief names the files, what done looks like, and the check to run (build or tests).
- Before reporting a non-trivial code change from a builder as done, run `reviewer` on the diff. Give it the task and the code, not your conclusion. Trivial changes (copy, one-liners, config) skip review.
- If a builder falls short: add a self-check first, then raise effort, then move up a model (builder -> senior-builder -> do it yourself).
