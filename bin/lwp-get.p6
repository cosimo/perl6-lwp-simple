#!/usr/bin/perl6

use LWP::Simple;

my $url = @*ARGS[0] // "http://www.rakudo.org";

say LWP::Simple.get($url);

