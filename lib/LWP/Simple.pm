# ----------------------
# LWP::Simple for Perl 6
# ----------------------
use v6;
use MIME::Base64;
use URI;

class LWP::Simple:auth<cosimo>:ver<0.08>;

our $VERSION = '0.08';

enum RequestType <GET POST>;

method base64encode ($user, $pass) {
    my $mime = MIME::Base64.new();
    my $encoded = $mime.encode_base64($user ~ ':' ~ $pass);
    return $encoded;
}

method has_basic_auth (Str $host) {

    # ^ <username> : <password> @ <hostname> $
    warn "has_basic_auth deprecated - not in p5 LWP simple and now returned by parse_url";
    if $host ~~ /^ (\w+) \: (\w+) \@ (\N+) $/ {
        my $user = $0.Str;
        my $pass = $1.Str;
        my $host = $2.Str;
        return $user, $pass, $host;
    }

    return;
}

method get (Str $url) {
    self.request_shell(RequestType::GET, $url)
}

method post (Str $url, %headers = {}, Any $content?) {
    self.request_shell(RequestType::POST, $url, %headers, $content)
}

method request_shell (RequestType $rt, Str $url, %headers = {}, Any $content?) {

    return unless $url;

    my ($scheme, $hostname, $port, $path, $auth) = self.parse_url($url);

    %headers{'Connection'} = 'close';
    %headers{'User-Agent'} //= "LWP::Simple/$VERSION Perl6/$*PERL<compiler><name>";

    if $auth {
        $hostname = $auth<host>;
        my $user = $auth<user>;
        my $pass = $auth<password>;
        my $base64enc = self.base64encode($user, $pass);
        %headers<Authorization> = "Basic $base64enc";
    }

    %headers<Host> = $hostname;

    if ($rt ~~ RequestType::POST && $content.defined) {
        # Attach Content-Length header
        # as recommended in RFC2616 section 14.3.
        # Note: Empty content is also a content,
        # header value equals to zero is valid.
        %headers{'Content-Length'} = $content.bytes;
    }

    my ($status, $resp_headers, $resp_content) =
        self.make_request($rt, $hostname, $port, $path, %headers, $content);

    # Follow redirects. Shall we?
    if $status ~~ m/ 30 <[12]> / {

        my %resp_headers = $resp_headers.hash;
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

        return self.request_shell($rt, $new_url, %headers, $content);
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
            $length = :16(~$/);
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

method make_request (
    RequestType $rt, $host, $port as Int, $path, %headers, $content?
) {

    my $headers = self.stringify_headers(%headers);

    my $sock = IO::Socket::INET.new(:$host, :$port);
    my $req_str = $rt.Stringy ~ " {$path} HTTP/1.1\r\n"
        ~ $headers
        ~ "\r\n";

    # attach $content if given
    # (string context is forced by concatenation)
    $req_str ~= $content if $content.defined;

    $sock.send($req_str);

    # a bit crude w respect to err handling and blocking but ok for now
    my $resp = ~ gather for $sock.recv() xx * { .bytes ?? take $_ !! last };
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

    return $status_line, %header.item, @content.item;
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
    my $u = URI.new($url);
    my $path = $u.path_query;

    my $user_info = $u.grammar.parse_result<URI_reference><URI><hier_part><authority><userinfo>;

    return (
        $u.scheme,
        $user_info ?? "{$user_info}@{$u.host}" !! $u.host,
        $u.port,
        $path eq '' ?? '/' !! $path,
        $user_info ?? {
            host => $u.host,
            user => ~ $user_info[0]<likely_userinfo_component>[0],
            password => ~ $user_info[0]<likely_userinfo_component>[1]
        } !! Nil
    );
}

method stringify_headers (%headers) {
    my $str = '';
    for sort %headers.keys {
        $str ~= $_ ~ ': ' ~ %headers{$_} ~ "\r\n";
    }
    return $str;
}

