use v6;
use Test;

plan 2;

my $s = IO::Socket::INET.new(:host('www.opera.com'), :port(80));
ok($s, 'Socket object created');

$s = IO::Socket::INET.new(
    host => 'www.opera.com',
    port => 80,
);
ok($s, 'Socket object created');

# XXX Some systems seem to fail to resolve the IPv6 address
#$s = IO::Socket::INET.new(
#    host => '2a03:2880:f001:6:face:b00c:0:2',
#    port => 80,
#    # TODO Can't get &PIO::PF_INET6 from outside of IO::Socket::INET
#    family => 3,
#);
#ok($s, 'Socket object to IPv6 address created');
