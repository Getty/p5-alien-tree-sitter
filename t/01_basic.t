use Test2::V0;
use Alien::Tree::Sitter;

ok( Alien::Tree::Sitter->can('cflags'), 'has cflags method' );
ok( Alien::Tree::Sitter->can('libs'),   'has libs method' );
ok( Alien::Tree::Sitter->can('version'),'has version method' );

my $cflags = Alien::Tree::Sitter->cflags;
ok( $cflags =~ m/-I/, 'cflags contains -I include path' );

my $libs = Alien::Tree::Sitter->libs;
ok( $libs =~ m/-ltree-sitter/, 'libs references libtree-sitter' );

is( Alien::Tree::Sitter->version, '0.20.8', 'vendored version is 0.20.8' );

# Headers are verified downstream: any consumer that builds a tree-sitter
# grammar (e.g. Text::Treesitter::Bash) will fail loudly if parser.h is
# not on the path returned by cflags. Smoke test stays light.

done_testing;