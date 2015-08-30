#
# Test the parse_url() method
#
 
use v6;
use Test;

use LWP::Simple;

plan 6;

my @test = (
    { User-Agent => 'Opera/9.80 (WinNT; 6.0) Version/10.60' },
    "User-Agent: Opera/9.80 (WinNT; 6.0) Version/10.60\r\n",
    { Connection => 'close' },
    "Connection: close\r\n",
);

for @test -> %headers, $expected_str {
    my $hdr_str = LWP::Simple.stringify_headers(%headers);
    is($hdr_str, $expected_str, 'OK - ' ~ $hdr_str);
}

my $hdr = LWP::Simple.stringify_headers({
    User-Agent => 'Chrome/5.0',
    Accept-Encoding => 'gzip',
    Accept-Language => 'en;q=1, it;q=0.8, no-NB;q=0.5, es;q=0.6',
    Connection => 'keepalive',
});

ok(
    $hdr.match('User-Agent: Chrome'),
    'Composite headers are stringified correctly'
);

ok(
    $hdr.match('Accept-Encoding: gzip'),
    'Composite headers are stringified correctly'
);

ok(
    $hdr.match('Connection: keepalive'),
    'Composite headers are stringified correctly'
);

ok(
    $hdr.match('Accept-Language: en;q=1'),
    'Composite headers are stringified correctly'
);

