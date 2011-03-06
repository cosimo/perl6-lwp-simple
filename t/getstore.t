use v6;
use Test;

use LWP::Simple;

my $fname = "./tmp-getstore-$*PID";
unlink $fname;

ok(
    LWP::Simple.getstore('http://www.opera.com', $fname),
    'getstore() returned success'
);

my $fh = open($fname);
ok($fh, 'Opened file handle written by getstore()');

my $found = 0;
for $fh.lines {
    when /Opera \s+ browser/ {
        $found = 1;
        last;
    }
}

ok($found, 'Found pattern in downloaded file');

ok(unlink($fname), 'Delete the temporary file');

done;

