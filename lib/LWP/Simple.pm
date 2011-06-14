# ----------------------
# LWP::Simple for Perl 6
# ----------------------
use v6;
use MIME::Base64;

class LWP::Simple:auth<cosimo>:ver<0.07>;

our $VERSION = '0.07';

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
        when "http"   { return 80  }
        when "https"  { return 443 }
        when "ftp"    { return 21  }
        when "ssh"    { return 22  }
        default       { return 80 }
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

method get (Str $url, %headers = {}, Any $content?) {

    return unless $url;

    my ($scheme, $hostname, $port, $path) = self.parse_url($url);

    %headers{'Connection'} = 'close';
    %headers{'User-Agent'} //= "Perl6-LWP-Simple/$VERSION";

    if my @auth = self.has_basic_auth($hostname) {
        $hostname = @auth[2];
        my $user = @auth[0];
        my $pass = @auth[1];
        my $base64enc = self.base64encode($user, $pass);
        %headers<Authorization> = "Basic $base64enc";
    }

    %headers<Host> = $hostname;

    if ($content.defined) {
        # Attach Content-Length header
        # as recommended in RFC2616 section 14.3.
        # Note: Empty content is also a content,
        # header value equals to zero is valid.
        %headers{'Content-Length'} = $content.bytes;
    }

    my ($status, $resp_headers, $resp_content) =
        self.make_request($hostname, $port, $path, %headers, $content);

    # Follow redirects. Shall we?
    if $status ~~ m/ 30 <[12]> / {

        my %resp_headers = $resp_headers;
        my $new_url = %resp_headers<Location>;
        if ! $new_url {
            say "Redirect $status without a new URL?";
            return;
        }

        # Watch out for too many redirects.
        # Need to find a way to store a class member
        #if $redirects++ > 10 {
        #    say "Too many redirects!";
        #    return;
        #}

        return self.get($new_url);
    }

    # Response successful. Return the content as a scalar
    if $status ~~ m/200/ {
        my $page_content = $resp_content.join("\n");
        return $page_content;
    }

    # Response failed
    return;
}

# In-place removal of chunked transfer markers
method decode_chunked (@content) {
    my $pos = 0;

    while @content {

        # Chunk start: length as hex word
        my $length = splice(@content, $pos, 1);

        # Chunk length is hex and could contain
        # chunk-extensions (RFC2616, 3.6.1). Ex.: '5f32; xxx=...'
        if $length ~~ m/^ \w+ / {
            $length = :16($length);
        } else {
            last;
        }

        # Continue reading for '$length' bytes
        while $length > 0 && @content.exists($pos) {
            my $line = @content[$pos];
            $length -= $line.bytes;    # .bytes, not .chars
            $length--;                 # <CR>
            $pos++;
        }

        # Stop decoding when a zero is encountered, RFC2616 again
        if $length == 0 {
            # Truncate document here
            splice(@content, $pos);
            last;
        }

    }

    return @content;
}

method make_request ($host, $port as Int, $path, %headers, $content?) {

    my $headers = self.stringify_headers(%headers);

    my $sock = IO::Socket::INET.new(:$host, :$port);
    my $req_str = "GET {$path} HTTP/1.1\r\n"
        ~ $headers
        ~ "\r\n";

    # attach $content if given
    # (string context is forced by concatenation)
    $req_str ~= $content if $content.defined;

    $sock.send($req_str);

    my $resp = $sock.recv();
    $sock.close();

    my ($status, $resp_headers, $resp_content) = self.parse_response($resp);

    return ($status, $resp_headers, $resp_content);
}

method parse_response (Str $resp) {

    my %header;
    my @content = $resp.split(/\n/);

    my $status_line = @content.shift;

    while @content {
        my $line = @content.shift;
        last if $line eq '';
        my ($name, $value) = $line.split(': ');
        %header{$name} = $value;
    }

    if %header.exists('Transfer-Encoding') && %header<Transfer-Encoding> ~~ m/:i chunked/ {
        @content = self.decode_chunked(@content);
    }

    return $status_line, \%header, \@content;
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

    my $fh = open($filename, :bin, :w);
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

    @path = $url.split(/\/+/, 3);
    $scheme = @path.shift;
    $scheme .= chop;
    $hostname = @path.shift;
    $path = '/' ~ (@path[0] // '');

    #say 'scheme:', $scheme;
    #say 'hostname:', $hostname;
    #say 'port:', $port;
    #say 'path:', @path;

    # rakudo: Regex with captures doesn't work here
    if $hostname ~~ /^ .+ \: \d+ $/ {
        ($hostname, $port) = $hostname.split(':');
        # sock.open() fails if port is a Str
        $port = $port.Int;
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

