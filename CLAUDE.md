# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt

`Alien::Tree::Sitter` ist ein `Alien::Base`/`Alien::Build`-Wrapper, der die
C-Library [tree-sitter](https://tree-sitter.github.io/tree-sitter/) Version
**0.20.8** als statisches Archiv `libtree-sitter.a` vendored und
Perl-Konsumenten (vor allem `Text::Treesitter` und Grammatiken wie
`Text::Treesitter::Bash`) per `cflags`/`libs` zur Verfügung stellt.

Primärzweck: ABI-stabile Bereitstellung der letzten 0.20.x-Version von
tree-sitter (0.20.8). Diese Reihe liefert noch `tree_sitter/parser.h` als
Canonical-Header; ab 0.22 wurde das in `tree_sitter/api.h` zusammengeführt
und die ABI-Kompatibilität mit 0.20.x-Grammatiken ist gebrochen.

## Setup / Build / Test

```bash
# Debian/Ubuntu (einmalig):
sudo apt-get install -y libpkgconf-dev gcc

# Perl-Dependencies:
cpanm --installdeps .

# Vollständiger Build + Install + Test (Dist::Zilla):
dzil install

# Nur Tests gegen bereits installiertes Modul:
prove -lv t/

# Einzeltest:
prove -lv t/01_basic.t
```

`dzil install` baut die Distribution in `.build/`, extrahiert das vendored
Tarball nach `_alien/build_XXX/tree-sitter/`, kompiliert daraus
`libtree-sitter.a` und legt es unter `share/dist/Alien-Tree-Sitter/lib/` ab
plus die Header unter `share/dist/Alien-Tree-Sitter/include/`.

## Architektur

```
Alien::Tree::Sitter                     (lib/Alien/Tree/Sitter.pm)
└── use base 'Alien::Base'              (erbt cflags/libs/version)

share/tree-sitter-0.20.8.tar.gz         (vendored Source, ~1 MB)
└── nach Extract: tree-sitter/
    ├── include/tree_sitter/parser.h
    ├── include/tree_sitter/api.h
    └── src/lib.c                       (Single-Translation-Unit → libtree-sitter.a)
```

### alienfile (`share { ... }`-Block)

1. `plugin 'PkgConfig' => (pkg_name => 'tree-sitter', minimum_version => '0.20')` — probiert zuerst System-Library.
2. `plugin 'Fetch::Local'` + `plugin 'Extract' => 'tar.gz'` — lädt die vendored tarball.
3. `build` — kompiliert `src/lib.c` mit `-O2 -fPIC -std=c99` zu `libtree-sitter.o`, daraus `ar rcs lib/libtree-sitter.a`.
4. `gather` — kopiert `include/`, `src/`, `lib/` nach `$(INSTALL_PREFIX)/`.
5. `meta->before_hook(gather_share => sub { ... })` — setzt `runtime_prop->{cflags, libs, libs_static, version}` **bevor** `Alien::Build::Plugin::Core::Gather` die Pfade vom Install-Prefix auf den Runtime-Prefix rewrite't und `_alien/alien.json` schreibt. Ohne diesen Hook landen die Props nicht in der JSON, und `Alien::Base` kann sie beim Laden nicht lesen — die `cflags`/`libs`-Methoden verschwinden dann.

### `runtime_prop` vs `meta->prop`

- `meta->prop->{...}` setzt Properties auf der Meta-Definition (für `Makefile.PL`-Erzeugung).
- `runtime_prop->{...}` ist das, was `Alien::Base::runtime_prop` aus `_alien/alien.json` zurücksliest und woraus `cflags`/`libs`/`version` ihre Werte holen.

Wir setzen **`runtime_prop`** im `before_hook(gather_share)`, weil die Werte zur Build-Zeit noch nicht feststehen (Stage- und Extract-Pfade kommen erst während `gather`).

## Konsumenten

```perl
use Alien::Tree::Sitter;
my $cflags = Alien::Tree::Sitter->cflags;   # "-I.../include"
my $libs   = Alien::Tree::Sitter->libs;     # "-L.../lib -ltree-sitter"
my $ver    = Alien::Tree::Sitter->version;  # "0.20.8"
```

Hauptkonsument: `Text::Treesitter::Bash` (siehe
`~/dev/p5-text-treesitter-bash/CLAUDE.md`) — bekommt damit konsistente
`cflags` für `Text::Treesitter::Language::build`.

## Conventions (getty / perl-core)

- `use Alien::Tree::Sitter;` immer oben — kein `require` als Lazy-Optimization.
- 2-space indent, kein Tab, keine trailing commas.
- `Path::Tiny` für File-IO.
- `Carp qw( croak )` für Fehler.
- Versionierung: `$VERSION` ist immer `next` (eine über CPAN). `cpanfile`
  pinnt gegen das released CPAN-`Alien::Base`/`Alien::Build`, nicht gegen
  Repo-Stand.
- Author-Plugin: `[@Author::GETTY]` mit `alien_build = 1`.

## Wichtige Dateien

- `alienfile` — Probe/Build/Gather-Pipeline.
- `lib/Alien/Tree/Sitter.pm` — Triviale Subklasse von `Alien::Base` (nur POD).
- `share/tree-sitter-0.20.8.tar.gz` — Vendored Upstream-Source (unverändert).
- `t/01_basic.t` — Smoke-Test (cflags/libs/version/header-Files).
- `cpanfile` — Runtime + Test deps.
- `dist.ini` — Dist::Zilla (`[@Author::GETTY]` mit `alien_build = 1`).
- `Changes` — `{{$NEXT}}` Template + Released-Versionen.

## Tests

```bash
prove -lv t/01_basic.t
```

Prüft:
- `cflags` enthält `-I include path`
- `libs` referenziert `-ltree-sitter`
- `version` ist exakt `0.20.8`
- `tree_sitter/parser.h` und `tree_sitter/api.h` existieren am Install-Prefix

## Bekannte Lücken / TODOs

- **PkgConfig `share {}` block**: aktuell wird die System-Library über
  `pkg-config` nur probed, aber der `sys {}`-Block ist leer. Wenn jemand
  `tree-sitter` System-weit installiert hat (Debian `libtree-sitter-dev`),
  wird das benutzt — sonst wird die share-Build-Pipeline getriggert.
- Kein `sys {}`-Block-Inhalt notwendig für das share-Verhalten, aber für
  saubere PkgConfig-Integration könnte man noch
  `plugin 'PkgConfig::CommandLine'` im `sys {}`-Block ergänzen.
