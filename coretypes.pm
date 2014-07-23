package coretypes;
our $VERSION = '0.01_02';

=head1 NAME

coretypes - declare my [const] int, num, str $@%variables

=head1 DESCRIPTION

Parse int, num and str as types, provide packages and implement the
changed datastructures.

We have to support two different implementations:

As backwards compatible CPAN extension implemented only as slow tie methods,
and 2nd in core with patched parser hooks targetting 5.18 and faster and
smaller structures.

Use those 3 new native types in declarations of lexical scalars, arrays and
hashes, but not in globals.
Add a new lexical type qualifier C<const>, see L<https://github.com/rurban/perl/commits/typed/ro>

    my int $i;         # no magic allowed, with type-optim and type checks.
    my num $d;      #               -"-
    our str $s;     #               -"-

    my int @array;     # typed IV array, with type-optim. and type checks.
    my int @array[20]; # typed and fixed-sized, with type and size checks.
    my const int @array; # typed IV array, with better type-optim. and type checks.

    my str %hash;   # typed PV hash, with type-optim. and type checks

    our const str %hash = {'foo' => 'bar'};
                       # perfect hash with type-optim. and type checks

This package does NOT handle attributes, as there is no compile-time
attribute hook for my lexicals yet, and attribute parsing and handling is unstable
and even considered dangerous (Attribute::Handler evals them).
Type qualifiers, such as C<const> or C<unsigned> can be parsed upfront as in C,
or rely on an additional C<CHECK_*_ATTRIBUTES> hook.

=head1 SEE ALSO

L<types> for the PP (C<pure-perl>) old implementation of type checks.

L<typesafety> for a PP implementation of type inference and type-checks.

L<Devel::TypeCheck> for the best PP implementation of general type inference.

L<https://github.com/rurban/perl/commits/typed/ro> for the const type qualifier.

L<https://github.com/rurban/perl/commits/typed/av> for typed arrays.

L<https://github.com/rurban/perl/commits/typed/hv> for typed hashes.

L<https://github.com/rurban/perl/commits/typed/ph> for perfect hashes.

L<https://github.com/rurban/perl/commits/typed/ck> for fast internal
type checks and optimizations.

L<https://github.com/rurban/perl/commits/typed/sv> for typed scalars.


=head1 AUTHOR

Reini Urban

=head1 COPYRIGHT AND LICENSE

This library is free software under the same terms as perl itself.

Copyright (c) 2012 Reini Urban

=cut

# We probably need to do all this during BEGIN or CHECK

CHECK {

  $::int::coretypes = $::num::coretypes = $::str::coretypes = $VERSION;
  return;

  # PERL_CORE only set during building
  if ($ENV{PERL_CORE}) {
    ;
  }

  require DynaLoader;
  our @ISA = q(DynaLoader);

  bootstrap coretypes $VERSION;

  # compiled into XS
  if ($coretypes::_PERL_CORE) {
    # not much to do. just check the patch or version
    warn "core parsing and data structures not yet implemented";
  } else {
    # start the Devel::Declare and tie dance
    warn "non-core Devel::Declare and Tie not yet implemented";
  }

  # maybe do type checks using types now
  # require types; types->import();
}

1;
