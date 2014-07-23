# This should work dual-live as ext/coretypes in core with builtin parser and datastructure patches,
# as well as back-compat Devel::Declare parser hooks for "my type $var" and slow, but flexible tie magic.

use strict;
#use 5.005062;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   'NAME'		=> 'coretypes',
   'VERSION_FROM'	=> 'coretypes.pm',
   'PREREQ_PM'	=>
   {
     ($ENV{PERL_CORE} ? () : (
	#'Devel::Declare' => 0,
      ))
   },
   ABSTRACT_FROM => 'coretypes.pm',
   AUTHOR        => 'Reini Urban',
   ($ExtUtils::MakeMaker::VERSION gt '6.46' ?
    ('META_MERGE'  =>
     {
      resources =>
      {
       repository  => 'http://github.com/rurban/coretypes',
       license     => 'http://dev.perl.org/licenses/',
      },
     }
    ) : ()),
    SIGN => 1
  );


package MY;
use Config;

sub depend {
  "
README : \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README

release : dist
	git commit -a -m\"release \$(VERSION)\"
	git tag \$(VERSION)
	cpan-upload \$(DISTVNAME).tar\$(SUFFIX)
	git push
	git push --tags

gcov : \$(BASEEXT).c.gcov \$(BASEEXT).gcov cover_db/\$(BASEEXT)-xs.html

\$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov : \$(BASEEXT).xs
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -fprofile-arcs -ftest-coverage\" LDDLFLAGS=\"\$(LDDLFLAGS) -fprofile-arcs -ftest-coverage\"
	gcov \$(BASEEXT).c \$(BASEEXT).xs

cover_db/\$(BASEEXT)-xs.html : \$(BASEEXT).xs.gcov
	PERL5OPT=-MDevel::Cover make test
	-$^X -S gcov2perl \$(BASEEXT).c.gcov \$(BASEEXT).xs.gcov
	$^X -S cover

gprof :
	\$(MAKE) CCFLAGS=\"\$(CCFLAGS) -pg\" LDDLFLAGS=\"\$(LDDLFLAGS) -pg\"
"
}
