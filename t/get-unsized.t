use v6;
use Test;

use LWP::Simple;

plan 1;

# this page is, for now, delivered by a server that does not provide
# a content length or do chunking
my $html = LWP::Simple.get('http://rakudo.org');

ok(
    $html.match('Perl 6') &&
        $html.match('</html>') && $html.chars > 12_000,
    'make sure we pulled whole document without, we believe, sizing from server'
);
