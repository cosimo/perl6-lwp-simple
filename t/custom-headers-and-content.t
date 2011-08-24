use v6;
use Test;

use LWP::Simple;

my $host = 'http://www.software-path.com/was-cgi/json_rpc_server_test.cgi';
my %headers = ( 'Content-Type' => 'application/json' );
my $content = '{"method":"echo","params":["Hello from Perl6"],"id":1}';

my $html = LWP::Simple.post($host, %headers, $content);

ok(
    $html.match('Hello from Perl6'),
    'call to JSON-RPC service using headers and content params'
);

done;

