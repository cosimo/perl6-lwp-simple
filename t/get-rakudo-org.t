use v6;
use Test;

use LWP::Simple;

my $html = LWP::Simple.get('http://www.rakudo.org');

ok(
    $html.match('Rakudo Perl'),
    'homepage is downloaded and has "Rakudo Perl" in it'
);

done_testing;

