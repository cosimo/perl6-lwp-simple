use v6;
use Test;

use LWP::Simple;

plan 1;

# don't use rakudo.org anymore, it has proven to be rather unreliable :(
my $html = LWP::Simple.get('http://jigsaw.w3.org/HTTP/300/301.html');

ok(
    $html.match('Redirect test page'),
    'Was redirected to w3 redirect test page'
);

#diag("Content\n" ~ $html);

