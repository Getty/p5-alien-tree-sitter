# Alien::Tree::Sitter

Find or build a vendored [tree-sitter](https://tree-sitter.github.io/tree-sitter/)
C library (currently v0.20.8) for use by Perl modules that need to compile or
link against it.

## Synopsis

```perl
use Alien::Tree::Sitter;

# For XS consumers (compile a grammar against tree-sitter)
my $cflags = Alien::Tree::Sitter->cflags;
my $libs   = Alien::Tree::Sitter->libs;

my $ver = Alien::Tree::Sitter->version;   # 0.20.8
```

## Description

This Alien-style distribution vendors the tree-sitter C library so that
consumers like [`Text::Treesitter`](https://metacpan.org/pod/Text::Treesitter)
and its grammar plugins
([`Text::Treesitter::Bash`](https://metacpan.org/pod/Text::Treesitter::Bash),
[`Text::Treesitter::Perl`](https://metacpan.org/pod/Text::Treesitter::Perl),
...) can compile grammars against a known ABI.

It first checks whether a system `libtree-sitter` is available via
`pkg-config`. If not, it builds tree-sitter from a bundled source tarball
(`share/tree-sitter-0.20.8.tar.gz`). No network access is required during
install.

### Why vendored at 0.20.8?

0.20.8 is the last release of the 0.20.x series, which still ships
`tree_sitter/parser.h` (the canonical header that upstream grammar
`parser.c` files `#include`). The 0.22 series removed `parser.h` and
unified everything into `tree_sitter/api.h`, breaking ABI compatibility
with grammars that target 0.20.x — and those grammars still ship on CPAN
(the most prominent example being `tree-sitter-bash 0.20.5`). Vendoring
0.20.8 keeps consumers like `Text::Treesitter::Bash` buildable regardless
of what the host distro provides.

## Installation

```bash
cpanm Alien::Tree::Sitter
```

Requires a C compiler. If `pkg-config tree-sitter` is not found (or
returns < 0.20), the module builds from the bundled tarball using the
single-translation-unit `src/lib.c`.

### Build dependencies (share install)

- C compiler (gcc / clang)
- `pkg-config` (system-library probe only)
- `ar` (static-archive creation)

## Methods

### `cflags`

String of C compiler flags (e.g. `-I/path/to/include`) suitable for
compiling a tree-sitter grammar against the vendored library.

### `libs`

String of linker flags (e.g. `-L/path/to/lib -ltree-sitter`) suitable for
linking against the vendored library.

### `libs_static`

Absolute path to the static archive `libtree-sitter.a`.

### `version`

Vendored tree-sitter version (currently `0.20.8`).

## Used by

- [`Text::Treesitter`](https://metacpan.org/pod/Text::Treesitter) — XS
  bindings to tree-sitter (statically links this archive).
- [`Text::Treesitter::Bash`](https://metacpan.org/pod/Text::Treesitter::Bash) —
  bash grammar, compiled against the vendored 0.20.8 ABI.

## See also

- [Alien::Build](https://metacpan.org/pod/Alien::Build)
- [Alien::Base](https://metacpan.org/pod/Alien::Base)
- [tree-sitter](https://tree-sitter.github.io/tree-sitter/)

## License

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.
