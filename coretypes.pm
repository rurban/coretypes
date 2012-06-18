package coretypes;
our $VERSION = '0.01_01';

=head1 NAME

coretypes - my int, double, string $@%variables

=head1 DESCRIPTION

Parse int, double and string as type, provide packages and implement the
changed datastructures.

We have to support two different implementations:

As backwards compatible CPAN extension implemented only as slow tie methods,
and 2nd in core with patched parser hooks targetting 5.18 and faster and
smaller structures.

Use those 3 new native types in declarations of lexical scalars, arrays and
hashes, but not in globals.

    my int $i;         # no magic allowed, with type-optim and type checks.
    my double $d;      #               -"-
    our string $s;     #               -"-

    my int @array;     # typed IV array, with type-optim. and type checks.
    my int @array[20]; # typed and fixed-sized, with type and size checks.

    my string %hash;   # typed PV hash, with type-optim. and type checks

    our string %hash :constant = {'foo' => 'bar'};
                       # perfect hash with type-optim. and type checks

This package does NOT handle attributes, as there is no compile-time
attribute hook for my lexicals yet.
So optimizations for :constant or :read-only are deferred to later.

Possible constant syntax to replace attributes:

    my constant string %hash;

=head1 SEE ALSO

L<types> for the PP (C<pure-perl>) implementation of type checks.

L<typesafety> for the PP implementation of type inference and type-checks.

L<Devel::TypeCheck> for the best PP implementation of general type inference.

=head1 AUTHOR

Reini Urban

=head1 COPYRIGHT AND LICENSE

This library is free software under the same terms as perl itself.

Copyright (c) 2012 Reini Urban

=cut

# We probably need to do all this during BEGIN or CHECK

CHECK {

  $main::int::coretypes = $main::double::coretypes = $main::string::coretypes = $VERSION;

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
