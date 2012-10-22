use v6;
use Test;

use LWP::Simple;

# this page is, for now, delivered by a server that does not provide
# a content length or do chunking
my $html = LWP::Simple.get('http://www.rosettacode.org/wiki/Rosetta_Code');

ok(
    $html.match('About Rosetta Code') &&
        $html.match('</html>') && $html.chars > 12_000,
    'make sure we pulled whole document without, we believe, sizing from server'
);

done;
