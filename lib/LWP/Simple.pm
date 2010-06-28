# ----------------------
# LWP::Simple for Perl 6
# ----------------------

use v6;
use MIME::Base64;

class LWP::Simple {

    our $VERSION = 0.04;

    method base64encode ($user, $pass) {
        my $mime = MIME::Base64.new();
        my $encoded = $mime.encode_base64($user ~ ':' ~ $pass);
        return $encoded;
    }

    method default_port () {
        return 80;
    }

    method default_port (Str $scheme) {
        given $scheme {
            when ("http")   { return 80  }
            when ("https")  { return 443 }
            when ("ftp")    { return 21  }
            when ("ssh")    { return 22  }
            default { return 80 }
        }
    }

    method has_basic_auth (Str $host) {

        # ^ <username> : <password> @ <hostname> $
        if $host ~~ /^ (\w+) \: (\w+) \@ (\N+) $/ {
            my $host = $0.Str;
            my $user = $1.Str;
            my $pass = $2.Str;
            return $host, $user, $pass;
        }

        return;
    }

    method get (Str $url) {

        return unless $url;

        my ($scheme, $hostname, $port, $path) = self.parse_url($url);

        my %headers = (
            Accept => '*/*',
            User-Agent => "Perl6-LWP-Simple/$VERSION",
            Connection => 'close',
        );

        if my @auth = self.has_basic_auth($hostname) {
            $hostname = @auth[2];
            my $user = @auth[0];
            my $pass = @auth[1];
            my $base64enc = self.base64encode($user, $pass);
            %headers<Authorization> = "Basic $base64enc";
        }

        %headers<Host> = $hostname;

        my $headers_str = self.stringify_headers(%headers);

        my $sock = IO::Socket::INET.new();
        $sock.open($hostname, $port);
        $sock.send(
            "GET {$path} HTTP/1.1\r\n"
            ~ $headers_str
            ~ "\r\n"
        );

        my $page = $sock.recv();
        $sock.close();

        return $page;
    }

    method getprint (Str $url) {
        say self.get($url);
    }

    method getstore (Str $url, Str $filename) {
        return unless defined $url;

        my $content = self.get($url);
        if ! $content {
            return
        }

        my $fh = open($filename, :w);
        my $ok = $fh.print($content);
        $fh.close; 

        return $ok;
    }

    method parse_url (Str $url) {

        my $scheme;
        my $hostname;
        my $port;
        my @path;
        my $path;

        @path = $url.split(/\/+/);
        $scheme = @path.shift;
        $scheme .= chop;
        $hostname = @path.shift;
        $path = '/' ~ @path.join('/');

        #say 'scheme:', $scheme;
        #say 'hostname:', $hostname;
        #say 'port:', $port;
        #say 'path:', @path;

        # rakudo: Regex with captures doesn't work here
        if $hostname ~~ /^ .+ \: \d+ $/ {
            ($hostname, $port) = $hostname.split(':');
        }
        else {
            $port = self.default_port($scheme);
        }

        return ($scheme, $hostname, $port, $path);
    }

    method stringify_headers (%headers) {
        my $str = '';
        for sort %headers.keys {
            $str ~= $_ ~ ': ' ~ %headers{$_} ~ "\r\n";
        }
        return $str;
    }

}

1;

