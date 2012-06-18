# This should work dual-live as ext/coretypes in core with builtin parser and datastructure patches,
# as well as back-compat Devel::CallChecker and tie magic.

use strict;
use 5.005062;
use ExtUtils::MakeMaker;
use Config;
use ExtUtils::Embed qw(ccopts ldopts);

my $extracflags = '';
my $verbose = grep {$_ eq '-v' } @ARGV;
my $lddlflags = $Config{lddlflags};
if ($^O eq 'darwin') {
  $lddlflags =~ s/-flat_namespace/-twolevel_namespace/;
  $lddlflags =~ s/-undefined suppress/-undefined error/;
}
my $ccflags = $Config{ccflags};
$ccflags .= " $extracflags";
my $obj = $Config{obj_ext};

sub checkexport {
  my $sym = shift;
  open C, ">", "test.c";
  print C << "EOF";
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "perlapi.h"
#include "XSUB.h"

int main (int argc, char **argv) {
  pTHXx;
  $sym;
}
EOF
  close C;

  my $cflags = ccopts;
  my $exe = $Config{exe_ext};
  my $redir = $^O eq 'MSWin32' ? "> NUL" : "2>/dev/null >/dev/null";
  my $psym = $sym; 
  @_ ? $psym = shift : $psym =~ s/\n/ /g;
  print "\nTesting libperl export for $psym\n";

  my $coredir = $ENV{PERL_SRC} || "$Config{installarchlib}/CORE";
  my $libdir  = "$Config{prefix}/lib";
  my $useshrplib = $Config{useshrplib};
  my $linkargs;
  if ($^O eq 'MSWin32' && $Config{cc} =~ m/^cl/i) {
    my $cmd = "$Config{cc} $cflags -c $redir";
    print "  $cmd\n" if $verbose;
    system($cmd);
    my $ok = ($? == 0) and -e "test.obj";
    return 0 unless $ok;

    $linkargs = ldopts("-std");
    $linkargs .= " perl5$Config{PERL_VERSION}.lib kernel32.lib msvcrt.lib";
    $cmd = "$Config{ld} test.obj $linkargs $redir";
    print "  $cmd\n" if $verbose;
    system $cmd;
  }
  else {
    if ( -e "$coredir/$Config{libperl}" and $Config{libperl} !~ /\.(dll|so)$/ ) {
      # prefer static linkage manually, without broken ExtUtils::Embed 
      $linkargs = sprintf("%s $coredir/$Config{libperl} %s",
			  @Config{qw(ldflags libs)});
    } elsif ( $useshrplib and -e "$libdir/$Config{libperl}") {
      # debian: /usr/lib/libperl.so.5.10.1 and broken ExtUtils::Embed::ldopts
      $linkargs = ExtUtils::Embed::ldopts('-std');
      $linkargs =~ s|-lperl |$libdir/$Config{libperl} |;
    } else {
      $linkargs = ExtUtils::Embed::ldopts('-std');
    }
    my $cmd = "$Config{cc} $ccflags -I$coredir test.c $linkargs $redir";
    print "  $cmd\n" if $verbose;
    system $cmd;
  }
  my $ok = $? == 0;
  print $ok ? "ok" : "not found";
  return $ok;
}

unless ($broken_plat) {
  END { unlink "a.out", "a.exe", "test.exe", "test$obj", "test.c"; };
  $ccflags .= " -DHAVE_PAD_ALLOC"
    if checkexport("Perl_pad_alloc(aTHX_ 0, SVs_PADTMP)", "pad_alloc");
  $ccflags .= " -DHAVE_CV_CLONE"
    if checkexport("CV* cv;\nPerl_cv_clone(aTHX_ cv)", "cv_clone");
  $ccflags .= " -DHAVE_FOLD_CONSTANTS"
    if checkexport("OP* o;\n".($]<5.011?"Perl":"S")."_fold_constants(aTHX_ o)",
		   "fold_constants");
  print "\n";
} # else -DDISABLE_PERL_CORE_EXPORTED

WriteMakefile
  (
   'NAME'		=> 'coretypes',
   'VERSION_FROM'	=> 'coretypes.pm',
   'PREREQ_PM'	=>
   {
     ($ENV{PERL_CORE} ? () : (
	'Devel::CallChecker' => 0,
	'ExtUtils::CBuilder' => 0,
	'ExtUtils::Embed'    => 0))
   },
   ABSTRACT_FROM => 'coretypes.pm',
   AUTHOR        => 'Reini Urban',
   (($^O eq 'darwin') ?
    (LDDLFLAGS     => $lddlflags) : ()),
   CCFLAGS        => $ccflags,
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

# sub const_config {
#   my $s = shift->SUPER::const_config(@_);
#   return $s unless $^O eq 'darwin';
#   my ($lddlflags) = $s =~ /^LDDLFLAGS (.*)$/m;
#   $lddlflags =~ s/-flat_namespace/-twolevel_namespace/;
#   $lddlflags =~ s/-undefined suppress/-undefined error/;
#   $lddlflags .= " $Config{archlibexp}/CORE/$Config{libperl}";
#   $s =~ s/^LDDLFLAGS (.*)$/LDDLFLAGS $lddlflags/;
#   return $s;
# }

# Modules using coretypes should do the same
#sub test {
#  local $_ = shift->SUPER::test(@_);
#  s/PERL_DL_NONLAZY=1 //g;
#  return $_;
#}

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
