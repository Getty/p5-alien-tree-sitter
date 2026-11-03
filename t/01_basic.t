#!/usr/bin/env perl
use Test2::V0;
use File::Spec;
use JSON::PP ();
use Alien::Tree::Sitter;

sub slurp {
  my ($file) = @_;
  open my $fh, '<', $file or return '';
  local $/;
  return scalar <$fh>;
}

my $install_type = Alien::Tree::Sitter->install_type;
my $cflags       = Alien::Tree::Sitter->cflags;
my $libs         = Alien::Tree::Sitter->libs;
my $version      = Alien::Tree::Sitter->version;

diag("install type: $install_type");
diag("cflags: [$cflags]");
diag("libs: [$libs]");
diag("version: [$version]");

ok( Alien::Tree::Sitter->can('cflags'), 'has cflags method' );
ok( Alien::Tree::Sitter->can('libs'),   'has libs method' );
ok( Alien::Tree::Sitter->can('version'),'has version method' );

# libs is the invariant: every consumer links tree-sitter through it, on the
# system and on the share path alike.
like( $libs, qr/-ltree-sitter\b/, 'libs references libtree-sitter' );

# cflags and version differ by install type:
#   * share  - headers live in the Alien's private prefix, so cflags MUST carry
#              an -I include path, and the version is the vendored one.
#   * system - pkg-config reports empty cflags when the headers sit on the
#              default include path, so the contract is only that cflags is
#              defined; the version is whatever the alienfile's probe accepts
#              (the 0.20.x series).
if ( $install_type eq 'share' ) {
  like( $cflags, qr/(?:^|\s)-I\S/, 'share cflags carries an -I include path' );
  is( $version, '0.20.8', 'vendored version is 0.20.8' );

  # The shipped tree-sitter.pc describes the installed library: its prefix is
  # the final install location recorded in alien.json, as with `make install`.
  my $dist_dir = Alien::Tree::Sitter->dist_dir;
  my $pc       = slurp( File::Spec->catfile( $dist_dir, 'lib', 'pkgconfig', 'tree-sitter.pc' ) );
  my $alien    = JSON::PP::decode_json( slurp( File::Spec->catfile( $dist_dir, '_alien', 'alien.json' ) ) );
  my ($pc_prefix) = $pc =~ /^prefix=(.*)$/m;
  is( $pc_prefix, $alien->{prefix}, 'tree-sitter.pc names the install prefix' );
  like( $pc, qr/^Version: 0\.20\.8$/m,             'tree-sitter.pc carries the vendored version' );
  like( $pc, qr/^Cflags: -I\$\{includedir\}$/m,    'tree-sitter.pc carries the include path' );
  like( $pc, qr/^Libs: -L\$\{libdir\} -ltree-sitter$/m, 'tree-sitter.pc carries the library' );
}
else {
  ok( defined $cflags,
    'system cflags defined (may be empty: headers on the default include path)' );
  like( $version, qr/^0\.20\.\d+$/, 'system version is in the 0.20.x series' );
}

# Headers are verified downstream: any consumer that builds a tree-sitter
# grammar (e.g. Text::Treesitter::Bash) will fail loudly if parser.h is
# not on the path returned by cflags. Smoke test stays light.

done_testing;
