#!/usr/bin/perl6

use v6;
use LWP::Simple;

my $url = @*ARGS[0] // "http://www.rakudo.org";

my LWP::Simple $lwp .= new;
$lwp.force_no_encode = True;
$lwp.getprint($url);

