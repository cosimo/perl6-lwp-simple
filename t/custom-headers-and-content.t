use v6;
use Test;

use LWP::Simple;

# This test uses live JSON-RPC demo service located at:
# http://jsolait.net/services/test.jsonrpc

my $host= 'http://jsolait.net/services/test.jsonrpc';
my %headers = ( 'Content-Type' => 'application/json' );
my $content = '{"method":"echo","params":["Hello from Perl6"],"id":1}';

my $html = LWP::Simple.get($host, %headers, $content);

# return line should looks like
# {"id": 1, "result": "Hello from Perl6", "error": null}

ok(
    $html.match('Hello from Perl6'),
    'call to JSON-RPC service using headers and content params'
);

done;

