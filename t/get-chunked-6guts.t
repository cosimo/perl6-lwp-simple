use v6;
use Test;

use LWP::Simple;

# would really be nice to verify in headers that it's really chunked
# but, for now, this is "Simple"
my $html = LWP::Simple.get('http://6guts.wordpress.com/2012/07/29/rakudo-qast-switch-brings-memory-reductions/');

ok(
    $html.match('masak++') && $html.match('</html>') && $html.chars > 30_000,
    'Pulled down whole chunked article'
);

done;
