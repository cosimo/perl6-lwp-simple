use LWP::Simple;
use v6;
use Test;
plan *;

my $resp_200 = q[HTTP/1.1 200 OK
Date: Mon, 25 Mar 2013 19:44:37 GMT
Server: GitHub.com
Content-Type: text/plain; charset=utf-8
Status: 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 100
X-Frame-Options: deny
Access-Control-Allow-Origin: https://render.github.com
X-Content-Type-Options: nosniff
Content-Disposition: inline
Content-Transfer-Encoding: binary
X-Runtime: 12
ETag: "b9834ff6fe642510e9753dd6fc13db72"
Content-Length: 334
Accept-Ranges: bytes
Via: 1.1 varnish
Age: 0
X-Served-By: cache-a15-AMS
X-Cache: MISS
X-Cache-Hits: 0
Vary: Accept-Encoding
Cache-Control: private

{
    "name"        : "LWP::Simple",
    "version"     : "0.08",
    "description" : "LWP::Simple quick & dirty implementation for Rakudo Perl 6",
    "depends"     : [ "MIME::Base64", "URI" ],
    "author"      : "Cosimo Streppone",
    "authority"   : "cosimo",
    "source-url"  : "git://github.com/cosimo/perl6-lwp-simple.git"
}];

my $lwp = LWP::Simple.new;
{
	my ($status_line, $headers, $content) 
		= $lwp.parse_response($resp_200.encode("utf-8"));

	is $status_line, "HTTP/1.1 200 OK", "status line";
	is $headers<Date>, "Mon, 25 Mar 2013 19:44:37 GMT", "first header line";
	is $headers<Cache-Control>, "private", "last header line";
	ok $content.decode("utf-8") ~~ /^'{' .* '}'$/;
}

