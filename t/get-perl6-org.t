use v6;
use Test;

use LWP::Simple;

plan 2;

# don't use rakudo.org anymore, it has proven to be rather unreliable :(
my $html = LWP::Simple.get('http://www.perl6.org');

ok(
    $html.match('Perl'),
    'homepage is downloaded and has "Perl" in it'
);

# a page over 64K would be ideal but a bit slow and not really needed yet
$html = LWP::Simple.get('http://doc.perl6.org/type.html');
ok(
    $html.match('X::Attribute::Undeclared') &&
        $html.match('</html>'),
    'make sure we pulled down whole document for some substantial size'
);
#diag("Content\n" ~ $html);
