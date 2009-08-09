#!/usr/bin/perl6

use LWP::Simple;

my $url = @*ARGS[0] // "http://www.rakudo.org";

LWP::Simple.getprint($url);

