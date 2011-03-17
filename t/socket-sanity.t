use v6;
use Test;

plan 1;

my $s = IO::Socket::INET.new(:host('72.14.176.61'), :port(80));
ok($s, 'Socket object created');

