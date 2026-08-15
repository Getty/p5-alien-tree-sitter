package Alien::Tree::Sitter;
# ABSTRACT: Build and provide access to a vendored tree-sitter C library
our $VERSION = '0.001';
use strict;
use warnings;
use base 'Alien::Base';

1;

__END__

=head1 NAME

Alien::Tree::Sitter - locate or build a vendored tree-sitter C library

=head1 SYNOPSIS

    use Alien::Tree::Sitter;

    my $cflags = Alien::Tree::Sitter->cflags;
    my $libs   = Alien::Tree::Sitter->libs;

=head1 DESCRIPTION

This distribution vendors the upstream L<tree-sitter|https://tree-sitter.github.io/tree-sitter/>
C library (currently v0.20.8) and provides it to other Perl modules that
need to compile or link against it. The most common consumer is
L<Text::Treesitter> and its language-grammar plugins
(L<Text::Treesitter::Bash>, L<Text::Treesitter::Perl>, ...).

The vendored source is kept under F<share/tree-sitter/> and contains the
same files upstream ships in its F<lib/> directory: F<src/lib.c>,
F<src/parser.c>, F<include/tree_sitter/api.h>,
F<include/tree_sitter/parser.h>. The header C<tree_sitter/parser.h> is the
canonical entry point that grammar F<parser.c> files include.

=head1 WHY

Debian and most Linux distros ship tree-sitter as C<libtree-sitter-dev>.
The header layout changes between major versions (the 0.22 series removed
C<parser.h> and unified everything into C<api.h>), so a grammar compiled
against 0.20.x often fails to link against the 0.22.x system library, and
vice versa. Vendoring eliminates that drift.

=head1 METHODS

=head2 cflags

Returns a string of C compiler flags (e.g. C<-I/path/to/include>) suitable
for compiling a tree-sitter grammar against the vendored library.

=head2 libs

Returns a string of linker flags (e.g. C<-L/path/to/lib -ltree-sitter>)
suitable for linking an executable against the vendored library. In most
setups the static archive is sufficient; the grammar .so typically picks
up the symbols from L<Text::Treesitter>'s own XS module at runtime.

=head2 version

Returns the vendored tree-sitter version (currently C<0.20.8>).

=head1 SEE ALSO

L<Text::Treesitter>, L<Text::Treesitter::Bash>,
L<https://tree-sitter.github.io/tree-sitter/>.

=cut