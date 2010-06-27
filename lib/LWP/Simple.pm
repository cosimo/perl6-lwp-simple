#!/usr/bin/env perl6

# ----------------------
# LWP::Simple for Perl 6
# ----------------------

class LWP::Simple {

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

    method get (Str $url) {

        return unless $url;

        my ($scheme, $hostname, $port, $path) = self.parse_url($url);

        my $sock = IO::Socket::INET.new();
        $sock.open($hostname, $port);
        $sock.send(
            "GET {$path} HTTP/1.1\r\n"
            ~ "Host: {$hostname}\r\n"
            ~ "Accept: */*\r\n"
            ~ "User-Agent: Perl6-LWP-Simple/0.02\r\n"
            ~ "Connection: close\r\n\r\n"
        );

        my $page = $sock.recv();
        $sock.close();

        return $page;
    }

    method getprint (Str $url) {
        say self.get($url);
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

        ($hostname, $port) = $hostname.split(':');
        if ! $port {
            $port = self.default_port($scheme);
        }

        return ($scheme, $hostname, $port, $path);
    }

}

1;

#say LWP::Simple.get("http://www.google.com");
#LWP::Simple.getprint('http://www.google.com');

