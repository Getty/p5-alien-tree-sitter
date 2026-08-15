use Test2::V0;
use Alien::Tree::Sitter;

ok( defined &Alien::Tree::Sitter::cflags, 'has cflags method' );
ok( defined &Alien::Tree::Sitter::libs,   'has libs method' );

my $cflags = Alien::Tree::Sitter->cflags;
ok( $cflags =~ m/-I/, 'cflags contains -I include path' );

my $libs = Alien::Tree::Sitter->libs;
ok( $libs =~ m/-ltree-sitter/, 'libs references libtree-sitter' );

is( Alien::Tree::Sitter->version, '0.20.8', 'vendored version is 0.20.8' );

# Confirm headers really exist on disk (the install prefix must contain them)
my ($inc) = $cflags =~ m/-I(\S+)/;
ok( -f "$inc/tree_sitter/parser.h", 'tree_sitter/parser.h header is present' );
ok( -f "$inc/tree_sitter/api.h",    'tree_sitter/api.h header is present' );

done_testing;