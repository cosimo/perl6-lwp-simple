use v6;
use Test;

use LWP::Simple;

plan 2;

my $html = LWP::Simple.get('http://www.w3.org/2006/11/mwbp-tests/test-encoding-8.html');

my $find_char = chr(233); # small e with acute
ok(
    $html.match('</html>') && $html.match($find_char),
    'Got latin-1 page'
);

$html = LWP::Simple.get('http://www.w3.org/2006/11/mwbp-tests/test-encoding-3.html');
ok(
    $html.match('</html>') && $html.match($find_char),
    'Got utf-8 page'
);
#diag("Content\n" ~ $html);

