use v6;
use Test;

plan 2;

my $s = IO::Socket::INET.new(:host('72.14.179.21'), :port(80));
ok($s, 'Socket object created');

$s = IO::Socket::INET.new(
    host => '72.14.179.21',
    port => 80,
);
ok($s, 'Socket object created');

# Fails with getaddrinfo: inappropriate ioctl for device ??
#$s = IO::Socket::INET.new(
#    host => '2620:0:1cfe:face:b00c::3',
#    port => 80,
#    family => PIO::PF_INET6,
#);
#ok($s, 'Socket object to IPv6 address created');
