#!/usr/bin/perl
#
# A Perl TNFS server that should work on any operating system with a perl
# interpreter. It will run out the box on Linux, most BSDs and Mac OSX since
# these come with perl interpreters.
#
# Windows requires ActiveState Perl or Cygwin Perl.
#
# At the present time this is just a simple server allowing anonymous TNFS
# mounts. Its main purpose at present is for testing 8 bit clients and
# helping in protocol development.
#
# Usage: tnfsd <path to export>

use IO::Socket::INET;
use IO::Select;
use FileHandle;
use Data::Dumper;
use strict;

my $MAXSIZE=1024;	# largest TNFS datagram

my $root=shift();
if(!$root)
{
	print("Usage: tnfsd.pl <root directory>\n");
	exit(255);
}

# Define which TNFS command IDs should go to what functions.
my %TNFSCMDS=(	0x00	=> \&mount,
		0x01	=> \&umount );

# Sessions - clients that have mounted us
my %SESSION;		# Table of session ids to IP addresses
my %LASTMSG;		# Table of last messages for a session
my %MOUNTPOINT;		# Table of mount points for sessions

# Main program. Create the socket and listen for requests.
my $sock=IO::Socket::INET->new(LocalPort 	=> 16384,
			       Proto		=> 'udp')
	or die("Unable to create socket: $!");

my $msg;
my $port;
my $ipaddr;
while($sock->recv($msg, $MAXSIZE))
{
	($port, $ipaddr) = sockaddr_in($sock->peername);
	my $host = gethostbyaddr($ipaddr, AF_INET);

	my ($session, $retry, $cmd)=unpack("SCC", $msg);
	my $payload=substr($msg, 4);

	if($cmd != 0x00 && $ipaddr ne $SESSION{$session})
	{
		printf("$host: Session ID %x invalid\n", $session);
		sendMsg(0x00, $cmd, 0xFF);
		next;
	}
	
	if(defined $TNFSCMDS{$cmd})
	{
		$TNFSCMDS{$cmd}->($session, $retry, $cmd, $payload);
	}
	else
	{
		# reply ENOSYS 'operation not implemented'
		printf("$host: Operation %x not implemented\n", $cmd);
		sendMsg($session, $cmd, 0x16);
	}
}

close($sock);

##########################################################################
# TNFS functions.
#

# mount: Allow a client to mount a filesystem.
sub mount
{
	my ($session, $retry, $cmd, $message)=@_;
	
	# Only one mount point at present. Get the client major/minor
	# number.
	my ($cminor, $cmajor)=unpack("CC", $message);
	my ($mountpoint, $user, $pw)=split(/\x0/, substr($message,2));

	my $session=makeSessionId();

	# check the mount point actually exists
	if(opendir(DHND, $mountpoint))
	{
		closedir(DHND);
		$SESSION{$session}=$ipaddr;
		$MOUNTPOINT{$session}=$mountpoint;

		print("Mount: $mountpoint from $ipaddr\n");
		sendMsg($session, 0x00, 0x00, "\x00\x01\x00\x00");
	}
	else
	{
		# session is null, cmd is 0, error is ENOENT (0x02)
		# version is 1.0
		print("Mount: FAILED for $mountpoint from $ipaddr\n");
		sendMsg(0, 0x00, 0x02, "\x00\x01");
	}
}

sub sendMsg
{
	my ($session, $cmd, $status, $msg)=@_;
	my $dgram=pack("SCCC", $session, 0, $cmd, $status);
	$dgram .= $msg;
	$LASTMSG{$session}=$dgram;
	$sock->send($dgram);
}

sub makeSessionId
{
	my $sid;
	do
	{
		$sid=int(rand(65536));
	} while($SESSION{$sid});
	return $sid;
}

