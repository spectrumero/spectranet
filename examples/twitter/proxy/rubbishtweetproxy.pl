#!/usr/bin/perl
# rubbishtweetproxy v0.3
# This is an extremely hacky bit of perl since it's the first thing I've ever written in the language.
# As such it's mostly cobbled together from snippets found online and in documentation. It does seem to work though.
# The script acts as an http deamon on port 80, implementing a subset of the old twitter basic auth API by making
# https requests to twitter's mobile phone pages. The scraping of responses is fairly naiive and it only catches a
# a couple of the possible errors. The server forks so theoretically should be able to handle multiple clients simultaneously.
# Any incoming request other than a valid POST /1/statuses/update.json request generates error 400. If twitter rejects the credentials
# rubbishtweetproxy returns error 401. If something else goes wrong it returns error 500 and writes a message to stdout.
# The page returned for the request is text/plain and contains the reason for the status code as plain text.

# Sometimes the request to twitter.com gets captcha'd. The reason for this is still unclear. This causes an error 500

use HTTP::Daemon;
use HTTP::Status;
use HTTP::Cookies;
use LWP::UserAgent;

$cookie_jar = HTTP::Cookies->new;

my $ua = LWP::UserAgent->new;
$ua->cookie_jar( $cookie_jar );
  
sub get_token {
	$cookie_jar->clear;
	my $response = $ua->get( 'https://mobile.twitter.com/session/new' );

	substr $response->decoded_content, index($response->decoded_content, 'authenticity_token') + 41, 20;
};

sub log_in {
	my $response = $ua->post( 'https://mobile.twitter.com/session', 'referer'=>'https://mobile.twitter.com/session/new', Content=>[ authenticity_token=>$_[0], username=>$_[1], password=>$_[2], commit=>'Sign+in' ] );
	
	#print $response->decoded_content,"\n";
	
	if (index($response->decoded_content, 'Double-check your username and password and try again.') != -1)
	{
		return -1;
	}
	elsif (index($response->decoded_content, "The words you typed didn't match. Try again!") != -1)
	{
		print "uh-oh: we got captcha'd\n";
		return -2;
	}
	return 0;
};

sub handle_connection {
	my $c = $_[0];
	my $r = $c->get_request();
	if ($r->method eq 'POST' and $r->uri->path eq "/1/statuses/update.json") {
		@auth = $r->authorization_basic;
		my $tweet = substr $r->content,7;
		
		my $token = get_token; #get the session token
		#print $token,"\n";
		
		my $err = log_in($token,$auth[0],$auth[1]);
		#print $err,"\n";
		if ($err == 0){
			my $response = $ua->post( 'https://mobile.twitter.com', 'referer'=>'https://mobile.twitter.com/compose/tweet', Content=>[ authenticity_token=>$token, 'tweet[text]'=>$tweet, commit=>'Tweet'] );
			if (index($response->decoded_content, 'Tweet was not sent') == -1){
				$c->send_response( RC_OK, OK => [ 'Content-Type' => 'text/plain' ], 'tweet ok' );
				print "yay: tweet succeeded\n";
			} else {
				$c->send_response( RC_INTERNAL_SERVER_ERROR, INTERNAL_SERVER_ERROR => [ 'Content-Type' => 'text/plain' ], "tweet failed" );
				print "uh-oh: tweet failed\n";
			};
		} elsif ($err == -1){
			$c->send_response( RC_UNAUTHORIZED, UNAUTHORIZED => [ 'Content-Type' => 'text/plain' ], 'bad password' );
			print "uh-oh: bad password\n";
		} elsif ($err == -2){
			$c->send_response( RC_INTERNAL_SERVER_ERROR, INTERNAL_SERVER_ERROR => [ 'Content-Type' => 'text/plain' ], "captcha'd" );
		};
	} else {
		$c->send_response( RC_BAD_REQUEST, BAD_REQUEST => [ 'Content-Type' => 'text/plain' ], 'this server only accepts POST requests to /1/statuses/update.json' );
		print "uh-oh: not a POST request to /1/statuses/update.json\n";
	};

	print "closing connection\n";
	$c->close;
	undef($c);
};

print "rubbishweetproxy v0.3\n";

my $d = HTTP::Daemon->new(LocalPort => 80) || die;
while (my $c = $d->accept) {
	next if $pid = fork;
	die "fork: $!" unless defined $pid;
	print "Forked child\n";
	handle_connection( $c );
	exit;
};
