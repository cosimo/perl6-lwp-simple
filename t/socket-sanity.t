use v6;
use Test;

plan 2;

my $s = IO::Socket::INET.new;
ok($s, 'Socket object created');

#my $opened = $s.open('www.rakudo.org', 80);
my $opened = $s.open('72.14.176.61', 80);
ok($opened, 'Socket to www.rakudo.org:80 opened');

if ! $opened {
    diag("Failed opening the socket: $opened");
}

