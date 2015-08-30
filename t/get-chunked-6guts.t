use v6;
use Test;

use LWP::Simple;

plan 1;

# would really be nice to verify in headers that it's really chunked
# but, for now, this is "Simple"
my $html = LWP::Simple.get('http://strangelyconsistent.org/blog/youre-in-a-space-of-twisty-little-mazes-all-alike/');

ok(
    $html.match('masak') && $html.match('</html>') && $html.chars > 20_000,
    'Pulled down whole chunked article'
);
