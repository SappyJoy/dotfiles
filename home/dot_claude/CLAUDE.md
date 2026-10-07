# Preferences

## Architecture
- Always prefer a SOLID, modular architecture: split work into small modules, each with a single clear role and explicit inputs and outputs.
- The goal is that solving any task needs only one small module in context. You should be able to read and change that module without loading the rest of the system.
- Keep module boundaries narrow. Modules should depend on interfaces or contracts, not on each other's internals.

## Git workflow
- Before starting a feature or fix, check that the working tree is clean. If it isn't, stop and ask me what to do with the changes (commit, stash, discard, or carry them over). Never decide on my behalf.
- Then create a branch from the main branch: `feat/<name>`, `fix/<name>`, etc.
- Commit as the work progresses, one logical change per commit (a module, a feature slice, a fix) — normal-sized commits, not micro-commits and not one big commit at the end. Each commit should build and pass tests.
- Use Conventional Commits: `type(scope): summary`, with types like `feat`, `fix`, `refactor`, `test`, `docs`, `build`, `chore`.
- When the feature is done, don't merge. Summarize the commits, suggest commands to review the branch (e.g. `git log --oneline <main>..<branch>`, `git diff --stat <main>...<branch>`, `git diff <main>...<branch>`, `/code-review`), and ask me whether to merge.
- In a project that uses milestone-flow (ROADMAP.md and .agent/milestones/), merge a finished milestone yourself unless it is a 🚦 gate; at a gate, stop with REVIEW.md. Uncommitted edits to INBOX.md there are my notes, not a dirty working tree.
- After merging a branch, delete it (`git branch -d <branch>`).
- Never push, force-push, or rewrite history without asking.

## Tips and suggestions
- My goal is a workstation that is as productive as it can be, improved step by step. Help me learn the tools I use.
- Now and then, when it fits what we're doing, end a reply with one short tip about a tool I already use: a shortcut, flag or hidden feature. Example: `Ctrl+Alt+F` in fzf.fish searches files; I found it by accident and use it all the time. One tip at a time, not in every reply.
- Also suggest tools I don't know yet when they would clearly help.
