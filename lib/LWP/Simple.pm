#!/usr/bin/env perl6

# ----------------------
# LWP::Simple for Perl 6
# ----------------------

use IO::Socket::INET;

class LWP::Simple {

	method get (Str $url) {

		return unless $url;

		my $proto;
		my $hostname;
		my ($path, @path);
		my $port;

		($proto, $hostname, @path) = $url.split(/\/+/);
		$proto .= chop;

		$path = '/' ~ @path.join('/');
		if ! $path {
			$path = '/';
		}

		($hostname, $port) = $hostname.split(':');
		if ! $port {
			$port = 80;
		}

		#say 'hostname:', $hostname;
		#say 'port:', $port;
		#say 'path:', $path;
		#say 'proto:', $proto;

		my $sock = IO::Socket::INET.new;
		$sock.open($hostname, $port);
		$sock.send(
			"GET {$path} HTTP/1.0\r\n"
			~ "Host: {$hostname}\r\n"
			~ "User-Agent: Perl6-LWP-Simple/0.01\r\n"
			~ "Connection: close\r\n\r\n"
		);
		my $page = $sock.recv();
		$sock.close();
		
		return $page;
	}

	method getprint (Str $url) {
		say self.get($url);
	}

}

1;

#say LWP::Simple.get("http://www.google.com");
#LWP::Simple.getprint('http://www.google.com');

