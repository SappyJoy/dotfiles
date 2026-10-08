# Preferences

## Coding
- Before you code, say what you assume. If the request can be read more than one way, or a simpler way would do, say so. Ask when a wrong guess would be costly to undo; otherwise take the simpler reading and name it.
- Turn the task into checks you can run: a test that reproduces a bug before you fix it, tests for new behaviour, the existing tests before and after a refactor. The task is done when they pass.
- Write the least code that does what was asked: no features, options or configurability nobody asked for, and no error handling for cases that can't happen. If 200 lines could be 50, rewrite them.
- Keep code in small modules, each with one clear role and explicit inputs and outputs, so that a task needs only one small module in context: you can read and change it without loading the rest. Other code uses a module's public functions and types, never its internals. New code with a role of its own gets a module of its own.
- A module is not an abstraction. Add an interface, base class, registry or plug-in point only when a second implementation exists now or a test needs one, not for one that might come.
- Touch only what the task needs. Don't reformat, rename or refactor the code around it, and match its style even where you'd write it differently. Remove what your change left unused; mention other dead code, or a refactor worth doing, instead of doing it.

## Git workflow
- Before starting a feature or fix, check that the working tree is clean. If it isn't, stop and ask me what to do with the changes (commit, stash, discard, or carry them over). Never decide on my behalf.
- Then create a branch from the main branch: `feat/<name>`, `fix/<name>`, etc.
- Commit as the work progresses, one logical change per commit (a module, a feature slice, a fix) — normal-sized commits, not micro-commits and not one big commit at the end. Each commit should build and pass quick tests of what it touches; run the full test suites once, on the last commit, before you report the feature done.
- Use Conventional Commits: `type(scope): summary`, with types like `feat`, `fix`, `refactor`, `test`, `docs`, `build`, `chore`.
- When the feature is done, don't merge. Tell me what it changes for me, without listing commits or git commands (I follow the changes in lazygit), and ask me whether to merge.
- In a project that uses milestone-flow (ROADMAP.md and .agent/milestones/), merge a finished milestone yourself unless it is a 🚦 gate; at a gate, stop with REVIEW.md. Uncommitted edits to INBOX.md or REVIEW.md there are my notes or my review reply, not a dirty working tree.
- After merging a branch, delete it (`git branch -d <branch>`).
- Never push, force-push, or rewrite history without asking.

## Tips and suggestions
- My goal is a workstation that is as productive as it can be, improved step by step. Help me learn the tools I use.
- Now and then, when it fits what we're doing, end a reply with one short tip about a tool I already use: a shortcut, flag or hidden feature. Example: `Ctrl+Alt+F` in fzf.fish searches files; I found it by accident and use it all the time. One tip at a time, not in every reply.
- Also suggest tools I don't know yet when they would clearly help.
