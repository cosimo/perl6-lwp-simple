use v6;
use Test;

use LWP::Simple;

# don't use rakudo.org anymore, it has proven to be rather unreliable :(
my $html = LWP::Simple.get('http://www.perl6.org');

ok(
    $html.match('Perl'),
    'homepage is downloaded and has "Perl" in it'
);

# a page over 64K would be ideal but a bit slow and not really needed yet
$html = LWP::Simple.get(
    'http://wiki.perl6.org/Mostly%20Harmless%20Docs/Operators'
);
ok(
    $html.match('That also works with the Z operator:') &&
        $html.match('</html>') && $html.bytes > 12_000,
    'make sure we pulled down whole document for some substantial size'
);
#diag("Content\n" ~ $html);

done;

