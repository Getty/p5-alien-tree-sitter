# Alien::Tree::Sitter House Rules

Apply to every task in this distribution unless explicitly overridden. Bias: caution over speed
on non-trivial work; use judgment on trivial tasks. Loaded automatically at launch (same priority
as `CLAUDE.md`). Skill content is never restated here: the skills are the source, and the agents
get them force-loaded via `briefing.skills`.

## Engineering discipline

1. **Think before coding** — State assumptions; ask rather than guess. Push back when a simpler approach exists. Stop when confused; name what's unclear.
2. **Simplicity first, surgically applied** — Minimum code that solves the problem, nothing
   speculative. This dist is deliberately small: an alienfile, a POD-only `.pm`, one smoke test. Touch only what you must.
3. **Goal-driven execution** — Define success criteria, loop until verified.
4. **Surface conflicts, don't average them** — Contradicting patterns: pick one, explain why, flag the other. Don't blend.
5. **Read before you write** — Read the `alienfile` end to end before changing any step; the probe, the build, the gather hook and the exposed props are one chain.
6. **Tests verify intent, not just behavior** — `t/01_basic.t` asserts the consumer contract;
   assert the actual flags and header paths, not a decoded proxy. Reproduce a bug before
   fixing it; leave the regression test behind.
7. **A red test is a claim before it is a failure** — Before changing code to turn a test green, say what the test asserts and whether your fix keeps that claim or replaces it.
8. **Checkpoint and fail loud** — Summarize done / verified / left after each significant
   step. "Done" is wrong if anything was skipped silently; "tests pass" is wrong if any were
   skipped — say so.
9. **Match the codebase's conventions, even if you disagree** — Conformance > taste.

## Delegation

If you can spawn subagents (orchestrating main agent): do NOT touch behavior-relevant code
yourself — delegate. Your lane: coordinate, inspect, plan, review diffs, run tests, edit
`Changes`/`README.md`. Only the `alien-tree-sitter-*` agents get their skills force-loaded via
`briefing.skills`; you get no briefing and would edit the alienfile without tree-sitter context.

| Task | Agent |
|---|---|
| Implement / refactor / debug the alienfile, the `.pm`, or `t/` | `alien-tree-sitter-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-tree-sitter-release-manager` |

If you ARE an `alien-tree-sitter-*` agent, the delegation lock does not apply — implement, refactor, debug and test per these rules.

Behavior-relevant = the `alienfile` (probe/build/gather/runtime_prop), `lib/Alien/Tree/Sitter.pm`, `t/`, and the vendored `share/` payload. Prose in `README.md` and `Changes` bullets are not.

**Only `alien-tree-sitter-release-manager` commits.** A worker leaves a commit-ready tree and hands
its card to `review`; you then dispatch `alien-tree-sitter-release-manager` to cut the commit and close the card.

## Coordination — karr board (always in scope)

Ticket coordination is the orchestrating agent's job, so `karr` is always in scope — don't invoke
the `kanban-issues-karr-coordination` skill first, just use it. Git-native kanban; state lives in `refs/karr/*`.

- `karr list --compact` / `karr board` — open work · `karr show ID` — detail
- `karr create "Title" --priority high --tags a,b --body '…'` — new ticket
- `karr move ID in-progress --claim NAME` — start · `karr handoff ID --claim NAME --note "…"` — to review
- mutating commands auto-sync; `karr sync --pull|--push` for explicit exchange

Record drift and follow-up work as tickets rather than growing the current change. **Serialize board mutations when fanning out** — parallel implementation is fine, but collect results and then loop `karr move`/`handoff`/`sync` sequentially — N of them landing at once is a resource event, not a cheap command.

## Release — never without permission

`dzil build` / `dzil test` are fine anytime. `dzil release` and any CPAN upload are STRICTLY
forbidden without the maintainer's explicit go-ahead — even if a ticket lists "release" as the next
step. For anything heading toward release: stop and ask. Only the local repo state matters; CPAN lag
is never a blocker and never a ticket.

## Project hazards — why this file is worth loading

Mechanism and background: skill `alien-tree-sitter-core`. These are the locks:

- **The vendored tarball is upstream-verbatim and pinned to 0.20.8 for ABI reasons.** 0.20.x still
  ships `tree_sitter/parser.h`; 0.22 removed it and breaks CPAN grammars that target 0.20.x. A version
  bump is a maintainer decision with a downstream-grammar audit, never a routine update — and the
  tarball itself is never repacked or patched.
- **`runtime_prop` must be set in `before_hook(gather_share)`**, before Core::Gather's prefix
  rewrite and `alien.json` write. Move it and the consumer's `cflags`/`libs` come back empty —
  the methods effectively disappear with no error at build time.
- **An untracked file does not exist as far as dzil is concerned.** `Git::GatherDir` skips it; `prove`
  runs it and passes while the release tarball omits it. `git add` new files as soon as they exist.
- **Only `alien-tree-sitter-core` is owned here; the other skills are build artifacts.** The
  ones `skilletor` installs are overwritten by the next `skilletor sync` — never edit them, they
  change in their source repo, via `skilletor`.

## Public issues (GitHub) — never act without instruction

`karr` is the internal agent board, churned freely. The GitHub issue tracker (`github.com/Getty/p5-alien-tree-sitter`) carries real people's reports, written under the maintainer's account. Never act on a public issue on your own initiative — not even to read it — unless the user points at a specific item.

## Perl / Alien conventions — reference, don't restate

House Perl style: `getty-perl-core`; Alien::Build mechanics: `perl-alien`; the XS/link side:
`perl-xs`; the release flow: `getty-perl-release-author-getty` and `perl-release-dist-ini`; this
distribution's own facts: `alien-tree-sitter-core` — all force-loaded via `briefing.skills`. Do not
duplicate them here.
