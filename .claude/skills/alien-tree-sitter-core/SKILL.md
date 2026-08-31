---
name: alien-tree-sitter-core
description: "Use when working on Alien::Tree::Sitter — the alienfile, the vendored tree-sitter 0.20.8 tarball, the libtree-sitter.a static build, or the cflags/libs/version this Alien exposes to Text::Treesitter consumers. Covers why 0.20.8, the runtime_prop-in-gather_share hook, and share-vs-system probing."
---

# Alien::Tree::Sitter — what this distribution actually decides

`Alien::Tree::Sitter` is a thin `Alien::Base` wrapper whose whole job is to hand a
**static `libtree-sitter.a` built from tree-sitter 0.20.8** — plus its headers — to
Perl consumers (chiefly `Text::Treesitter` and grammar dists like
`Text::Treesitter::Bash`) through the standard `cflags`/`libs`/`version` methods.

Generic alienfile / Alien::Base mechanics live in skill `perl-alien`; the XS/link side
in skill `perl-xs`. This skill is only the tree-sitter-specific invariants — read it
before touching `alienfile` or reasoning about why a consumer's link broke.

## Pinned at 0.20.8 on purpose — do not bump

0.20.8 is the **last release of the 0.20.x series**. That series still ships
`tree_sitter/parser.h` as a canonical header, and upstream grammar `parser.c` files
`#include <tree_sitter/parser.h>`. 0.22 removed `parser.h`, folded everything into
`tree_sitter/api.h`, and broke ABI compatibility with 0.20.x grammars — and those
grammars still ship on CPAN (e.g. `tree-sitter-bash 0.20.5`). Bumping the vendored
version silently breaks every downstream grammar build. A version change is a
maintainer decision with a downstream-grammar audit, never a routine update.

The version string `0.20.8` appears in three places that must agree: the tarball name
`share/tree-sitter-0.20.8.tar.gz`, `start_url`, and `runtime_prop->{version}`.

## share vs system

`plugin 'PkgConfig' => (pkg_name => 'tree-sitter', minimum_version => '0.20')` runs the
probe: if the host has a `pkg-config`-visible `libtree-sitter >= 0.20` (e.g. Debian
`libtree-sitter-dev`), the `sys {}` path uses it and the whole `share {}` block is
skipped. Otherwise the probe fails and `share {}` builds from the bundled tarball. No
network is ever needed — the source is vendored, fetched via `Fetch::Local`.

## The build is one translation unit

`share/.../src/lib.c` `#include`-s every other `.c` in `src/`, so the build is a single
`cc` of `lib.c` into `libtree-sitter.o`, then `ar rcs lib/libtree-sitter.a`. Flags are
`-O2 -fPIC -std=c99`. `-fPIC` is load-bearing: the archive gets linked straight into
`Text::Treesitter`'s XS `.so`, and grammar `.so` files dlopen those symbols from the
already-loaded `Text::Treesitter` `.so` at runtime.

## The one non-obvious hook: runtime_prop in before_hook(gather_share)

This is the part a reader of the alienfile will get wrong. The `share {}` block sets
`cflags`/`libs`/`libs_static`/`version` on **`runtime_prop`** inside
`meta->before_hook(gather_share => sub {...})` — not via the plugin, not on
`meta->prop`.

- `meta->prop->{...}` feeds `Makefile.PL` generation at build time.
- `runtime_prop->{...}` is what `Alien::Base` reads back out of `_alien/alien.json` at
  load time; `cflags`/`libs`/`version` return *those* values.

They must be set in `before_hook(gather_share)` because the stage/extract/prefix paths
only exist during `gather`, and the hook must run **before**
`Alien::Build::Plugin::Core::Gather` rewrites install→runtime prefixes and writes
`alien.json`. Set them later and the props never reach the JSON, so on the consumer side
`cflags`/`libs` come back empty and the methods effectively vanish. The same hook also
hand-mirrors `include/`, `src/`, `lib/` into the staged prefix, because the bare `gather
[]` DSL alone does not populate the stage for this no-real-buildsystem layout.

Use `$prefix` (`install_prop->{prefix}`) — not the stage path — when composing the
`cflags`/`libs` strings, so Gather's prefix rewrite lands on them.

## The consumer contract

```perl
Alien::Tree::Sitter->cflags        # -I<prefix>/include
Alien::Tree::Sitter->libs          # -L<prefix>/lib -ltree-sitter
Alien::Tree::Sitter->libs_static   # absolute path to libtree-sitter.a
Alien::Tree::Sitter->version       # 0.20.8
```

`lib/Alien/Tree/Sitter.pm` is `use parent 'Alien::Base'` plus POD — no logic; do not add
any. Anything a consumer needs comes from `runtime_prop`, set in the alienfile.

The smoke test `t/01_basic.t` asserts exactly this contract: `cflags` carries an include
path, `libs` references `-ltree-sitter`, `version` is exactly `0.20.8`, and
`tree_sitter/parser.h` + `tree_sitter/api.h` exist at the install prefix. Those four are
the reason the distribution exists — a change that breaks any of them breaks
`Text::Treesitter::Bash`'s `Text::Treesitter::Language::build`.
