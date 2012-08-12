use v6;
use Test;

use LWP::Simple;

my $html = LWP::Simple.get('http://www.w3.org/2006/11/mwbp-tests/test-encoding-8.html');

my $find_char = Buf.new(0xE9).decode('latin-1');
ok(
    $html.match('</html>') && $html.match($find_char),
    'Got latin-1 page'
);

#diag("Content\n" ~ $html);

done;

