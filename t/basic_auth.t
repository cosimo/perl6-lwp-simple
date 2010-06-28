#
# Test the basic auth code path
#
 
use v6;
use Test;

use LWP::Simple;

my $basic-auth-url = 'https://cosimo:eelst@faveclub.eelst.com/elio/mp3s/';
my @url = LWP::Simple.parse_url($basic-auth-url);

is(@url[0], 'https', 'Scheme parsed correctly');
is(@url[1], 'cosimo:eelst@faveclub.eelst.com', 'Hostname contains basic auth info');
is(@url[2], 443, 'HTTPS demands port 443');
is(@url[3], '/elio/mp3s/', 'Path extracted correctly');

my ($user, $pass, $host) = LWP::Simple.has_basic_auth(@url[1]);

is($user, 'cosimo', 'Basic auth info extracted correctly: user');
is($pass, 'eelst',  'Basic auth info extracted correctly: pass');
is($host, 'faveclub.eelst.com',  'Basic auth info extracted correctly: hostname');

# Encode test
is(
    LWP::Simple.base64encode('someuser', 'somepass'),
    'c29tZXVzZXI6c29tZXBhc3M=',
    'Base64 encoding works'
);

done_testing;

