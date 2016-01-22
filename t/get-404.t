use v6;
use Test;

use LWP::Simple;

plan 1;

# these tests will fail if this url stops returning 404 response
throws-like {
    LWP::Simple.get('http://www.perl6.org/404');
},
X::LWP::Simple::Response,
status => rx:i:s/404 Not Found/;
