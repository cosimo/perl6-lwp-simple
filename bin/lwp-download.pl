#!/usr/bin/perl6

use v6;
use LWP::Simple;

my $url  = @*ARGS[0] // "http://www.rakudo.org";
my $file = @*ARGS[1] // "tmpfile-$*PID";

my $lwp = LWP::Simple.new;
$lwp.getstore($url, $file);

