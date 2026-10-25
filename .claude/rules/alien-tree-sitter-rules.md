# Alien::Tree::Sitter House Rules

The shared house rules come from skilletor — bundle `getty-cpan-dist@getty`: engineering
discipline, the delegation lock, the publish gate, karr coordination, CPAN release. They
load as `.claude/rules/.local.*.md`; if they are missing, run `skilletor sync` and publish
nothing until they load. This file adds what is true only here, and wins where it differs.

## What this repo is

Builds and provides access to a vendored tree-sitter C library — deliberately small: an
alienfile, a POD-only `.pm`, one smoke test. Read first: the `alienfile` end to end before
changing any step; the probe, the build, the gather hook and the exposed props are one
chain.

## Agent team

| Task | Agent |
|---|---|
| Implement / refactor / debug the alienfile, the `.pm`, or `t/` | `alien-tree-sitter-worker` (default) |
| Commits, `Changes`, card → done, pre-release audit | `alien-tree-sitter-release-manager` |
| Read-only research, audit, gap analysis | `alien-tree-sitter-worker` ("read-only, change nothing") |

Behavior-relevant = the `alienfile` (probe/build/gather/runtime_prop),
`lib/Alien/Tree/Sitter.pm`, `t/`, and the vendored `share/` payload. Prose in `README.md`
and `Changes` bullets are not.

## Hazards — mechanism and background: skill `alien-tree-sitter-core`

- **The vendored tarball is upstream-verbatim and pinned to 0.20.8 for ABI reasons.** 0.20.x
  still ships `tree_sitter/parser.h`; 0.22 removed it and breaks CPAN grammars that target
  0.20.x. A version bump is a maintainer decision with a downstream-grammar audit, never a
  routine update — and the tarball itself is never repacked or patched.
- **`runtime_prop` must be set in `before_hook(gather_share)`**, before Core::Gather's prefix
  rewrite and `alien.json` write. Move it and the consumer's `cflags`/`libs` come back empty
  — the methods effectively disappear with no error at build time.
- **`t/01_basic.t` asserts the consumer contract** — assert the actual flags and header
  paths, not a decoded proxy.
- **An untracked file does not exist as far as dzil is concerned.** `Git::GatherDir` skips
  it; `prove` runs it and passes while the release tarball omits it. `git add` new files as
  soon as they exist.
- **Only `alien-tree-sitter-core` is owned here; the other skills and the shared rules are
  build artifacts.** The ones `skilletor` installs are overwritten by the next
  `skilletor sync` — never edit them, they change in their source repo.

## Perl / Alien conventions — reference, don't restate

House Perl style: `getty-perl-core`; Alien::Build mechanics: `perl-alien`; the XS/link side:
`perl-xs`; the release flow: `getty-perl-release-author-getty` and `perl-release-dist-ini`;
this distribution's own facts: `alien-tree-sitter-core` — all force-loaded via
`briefing.skills`.
