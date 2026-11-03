#!/usr/bin/env perl
use Test2::V0;
use Alien::Build;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );

# The alienfile prefers a system libtree-sitter only inside the 0.20.x series:
# from 0.21.0 on tree_sitter/parser.h is no longer installed, which grammars
# targeting 0.20.x need. Probe against fake .pc files to pin that down without
# a real system library.

local $ENV{ALIEN_INSTALL_TYPE};
delete $ENV{ALIEN_INSTALL_TYPE};
delete local $ENV{PKG_CONFIG_PATH};

my $probe_type = sub {
  my ($version) = @_;
  my $dir = tempdir( CLEANUP => 1 );
  path($dir, 'tree-sitter.pc')->spew(<<"PC");
prefix=/nonexistent
includedir=\${prefix}/include
libdir=\${prefix}/lib

Name: tree-sitter
Description: fake tree-sitter for the probe test
Version: $version
Libs: -L\${libdir} -ltree-sitter
Cflags: -I\${includedir}
PC
  local $ENV{PKG_CONFIG_PATH} = $dir;
  my $build = Alien::Build->load('alienfile');
  $build->load_requires('configure');
  $build->load_requires('any');
  return $build->probe;
};

is( $probe_type->('0.20.7'), 'system', 'system 0.20.7 is accepted' );
is( $probe_type->('0.20.8'), 'system', 'system 0.20.8 is accepted' );
is( $probe_type->('0.6.3'),  'share',  'system 0.6.3 is too old, falls back to share' );
is( $probe_type->('0.21.0'), 'share',  'system 0.21.0 lacks parser.h, falls back to share' );
is( $probe_type->('0.22.6'), 'share',  'system 0.22.6 lacks parser.h, falls back to share' );
is( $probe_type->('0.25.0'), 'share',  'system 0.25.0 lacks parser.h, falls back to share' );

done_testing;
