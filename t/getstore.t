use v6;
use Test;

use LWP::Simple;

my $fname = "./tmp-getstore-$*PID";
unlink $fname;

ok(
    LWP::Simple.getstore('http://www.rakudo.org', $fname),
    'getstore() returned success'
);

my $fh = open($fname);
ok($fh, 'Opened file handle written by getstore()');

my $found = 0;
for $fh.lines {
    when /Rakudo \s+ Perl/ {
        $found = 1;
        last;
    }
}

ok($found, 'Found pattern in downloaded file');

ok(unlink($fname), 'Delete the temporary file');

done_testing;

