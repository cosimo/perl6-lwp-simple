#!/usr/bin/perl6

use v6;
use LWP::Simple;

my $url  = @*ARGS[0] // "http://www.rakudo.org";
my $file = @*ARGS[1] // "tmpfile-$*PID";

my $lwp = LWP::Simple.new;
$lwp.force_no_encode = True;
$lwp.getstore($url, $file);

