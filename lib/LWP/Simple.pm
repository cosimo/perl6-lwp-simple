# ----------------------
# LWP::Simple for Perl 6
# ----------------------
use v6;
use MIME::Base64;
use URI;

class LWP::Simple:auth<cosimo>:ver<0.08>;

our $VERSION = '0.08';

enum RequestType <GET POST>;

has Str $.default_encoding = 'utf-8';

my Buf constant $crlf = Buf.new(13, 10);
my Buf constant $http_header_end_marker = Buf.new(13, 10, 13, 10);

method base64encode ($user, $pass) {
    my MIME::Base64 $mime .= new();
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
        %headers{'Content-Length'} = $content.encode.bytes;
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

# bug - is copy should be is rw
method parse_chunks(Buf $b is rw, IO::Socket::INET $sock) {
    my Int $line_end_pos = 0;
    my Int $chunk_len = 0;
    my Int $chunk_start = 0;
    my Buf $content .= new();

    while ($line_end_pos + 4 <= $b.bytes) {
        while ( $line_end_pos < $b.bytes  &&
                $b.subbuf($line_end_pos, 2) ne $crlf
        ) {
            $line_end_pos++
        }
#       say "got here x0x pos ", $line_end_pos, ' bytes ', $b.bytes, ' start ', $chunk_start, ' some data ', $b.subbuf($chunk_start, $line_end_pos +2 - $chunk_start).decode('ascii');
        if  $line_end_pos +2 <= $b.bytes &&
            $b.subbuf(
                $chunk_start, $line_end_pos + 2 - $chunk_start
            ).decode('ascii') ~~ /^(<.xdigit>+)[";"|"\r\n"]/ 
        {

            # deal with case of chunk_len is 0

            $chunk_len = :16($/[0].Str);
            # say 'got here ', $/[0].Str;

            # test if at end of buf??
            if $chunk_len == 0 {
                # this is a "normal" exit from the routine
                return True, $content;
            }

            # not sure if < or <=
            if $line_end_pos + $chunk_len + 4 < $b.bytes {
                # say 'inner chunk';
                $content ~= $b.subbuf($line_end_pos +2, $chunk_len);
                $line_end_pos = $chunk_start = $line_end_pos + $chunk_len +4;
            }
            else {
                # say 'last chunk';
                # remaining chunk part len is chunk_len with CRLF
                # minus the length of the chunk piece at end of buffer
                my $last_chunk_end_len = 
                    $chunk_len +2 - ($b.bytes - $line_end_pos -2);
                $content ~= $b.subbuf($line_end_pos +2);
                if $last_chunk_end_len > 2  {
                    $content ~= $sock.read($last_chunk_end_len -2);
                }
                # clean up CRLF after chunk
                $sock.read(min($last_chunk_end_len, 2));

                # this is a` "normal" exit from the routine
                return False, $content;
            }
        }
        else {
            # say 'bytes ', $b.bytes, ' start ', $chunk_start, ' data ', $b.subbuf($chunk_start).decode('ascii');
            # maybe odd case of buffer has just part of header at end
            $b ~= $sock.read(20);
        }
    }

    # say join ' ', $b[0 .. 100];
    # say $b.subbuf(0, 100).decode('utf-8');
    die "Could not parse chunk header";
}

method make_request (
    RequestType $rt, $host, $port as Int, $path, %headers, $content?
) {

    my $headers = self.stringify_headers(%headers);

    my IO::Socket::INET $sock .= new(:$host, :$port);
    my Str $req_str = $rt.Stringy ~ " {$path} HTTP/1.1\r\n"
        ~ $headers
        ~ "\r\n";

    # attach $content if given
    # (string context is forced by concatenation)
    $req_str ~= $content if $content.defined;

    $sock.send($req_str);

    my Buf $resp = $sock.read(2 * 1024);

    my ($status, $resp_headers, $resp_content) = self.parse_response($resp);


    if (    $resp_headers<Content-Length>   &&
            $resp_content.bytes < $resp_headers<Content-Length>
    ) {
        $resp_content ~= $sock.read(
            $resp_headers<Content-Length> - $resp_content.bytes
        );
    }

    if (($resp_headers<Transfer-Encoding> || '') eq 'chunked') {
        my Bool $is_last_chunk;
        my Buf $resp_content_chunk;

        ($is_last_chunk, $resp_content) =
            self.parse_chunks($resp_content, $sock);
        while (not $is_last_chunk) {
            ($is_last_chunk, $resp_content_chunk) =
                self.parse_chunks(
                    my Buf $next_chunk_start = $sock.read(1024),
                    $sock
            );
            $resp_content ~= $resp_content_chunk;
        }
    }

    $sock.close();

    # look for nicer way to code this
    my $charset = ($resp_headers<Content-Type> ~~ /charset\=(<-[;]>*)/)[0];
    $charset = $charset ?? $charset.Str !! $.default_encoding;

    return ($status, $resp_headers, $resp_content.decode($charset));
}

method parse_response (Buf $resp) {

    my %header;

    my Int $header_end_pos = 0;
    while ( $header_end_pos < $resp.bytes &&
            $http_header_end_marker ne $resp.subbuf($header_end_pos, 4)  ) {
        $header_end_pos++;
    }

    if ($header_end_pos < $resp.bytes) {
        my @header_lines = $resp.subbuf(
            0, $header_end_pos
        ).decode('ascii').split(/\r\n/);
        my Str $status_line = @header_lines.shift;

        for @header_lines {
            my ($name, $value) = .split(': ');
            %header{$name} = $value;
        }
        return $status_line, %header.item, $resp.subbuf($header_end_pos +4).item;
    }

    die "could not parse headers";
#    if %header.exists('Transfer-Encoding') && %header<Transfer-Encoding> ~~ m/:i chunked/ {
#        @content = self.decode_chunked(@content);
#    }

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
    my URI $u .= new($url);
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
    my Str $str = '';
    for sort %headers.keys {
        $str ~= $_ ~ ': ' ~ %headers{$_} ~ "\r\n";
    }
    return $str;
}

