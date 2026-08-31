# CLAUDE.md

Guidance for Claude Code in this repository. `Alien::Tree::Sitter` is an `Alien::Base`
wrapper that vendors tree-sitter **0.20.8** and hands a static `libtree-sitter.a` plus
headers to Text::Treesitter consumers via `cflags`/`libs`/`version`.

## Delegation

Delegate behavior-relevant code to the right agent instead of touching it yourself — the
principle, the lane definition and this dist's hazards are in
`.claude/rules/alien-tree-sitter-rules.md` (auto-loaded every turn).

| Task | Agent |
|---|---|
| Implement / refactor / debug the alienfile, `lib/Alien/Tree/Sitter.pm`, or `t/` | `alien-tree-sitter-worker` (default) |
| Pre-release audit | `alien-tree-sitter-release-checker` |

The agents carry their knowledge via `briefing.skills` (see `.claude/agents/`); the main
agent delegates rather than loading them. The tree-sitter specifics — why 0.20.8, the
`runtime_prop`-in-`gather_share` hook, share-vs-system, the consumer contract — live in
skill `alien-tree-sitter-core` under `.claude/skills/`; the rest of the skills there are
hardlinks from the shared library, maintained via `manage-skills` in their home repos.

## Build / test

```bash
cpanm --installdeps .
dzil test            # full share build + smoke test
prove -lv t/01_basic.t
```

Coordination is a `karr` board in this repo (`karr board`). Never `dzil release` without
the maintainer's explicit go-ahead.
