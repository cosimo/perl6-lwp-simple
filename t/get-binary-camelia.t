use v6;
use Test;

use LWP::Simple;

# don't use rakudo.org anymore, it has proven to be rather unreliable :(
my $logo = LWP::Simple.get('http://www.perl6.org/camelia-logo.png');

ok(
    $logo.bytes == 68382 && $logo[ 60_000 ] == 74,
    'Fetched Camelia Logo'
);


done;

