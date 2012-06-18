# -*- perl -*-
use Test::More;
$numtests = 1;
use coretypes;

if (!$coretypes::_PERL_CORE) {
  plan tests => $numtests;
} else {
  plan skip_all => "back-compat cpan release, not core";
}

ok 1;
