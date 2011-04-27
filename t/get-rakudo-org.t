use v6;
use Test;

use LWP::Simple;

# don't use rakudo.org anymore, it has proven to be rather unreliable :(
my $html = LWP::Simple.get('http://www.perl6.org');

ok(
    $html.match('Perl'),
    'homepage is downloaded and has "Perl" in it'
);

#diag("Content\n" ~ $html);

done;

