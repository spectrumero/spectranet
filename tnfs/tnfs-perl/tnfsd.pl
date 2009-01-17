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
		0x01	=> \&umount,
		0x10	=> \&opendir,
		0x11	=> \&readdir,
		0x12	=> \&closedir );

# Sessions - clients that have mounted us
my %SESSION;		# Table of session ids to IP addresses
my %LASTMSG;		# Table of last messages for a session
my %MOUNTPOINT;		# Table of mount points for sessions
my %DIRHANDLE;		# Table of directory handles
my %FILEHANDLE;		# Table of file handles

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

# opendir: Open a directory handle.
sub opendir
{
	my ($session, $retry, $cmd, $message)=@_;
	
	# remove terminating characters or illegal sequences
	$message=~s/\x0|\.\.//g;
	my $path="$MOUNTPOINT{$session}/$message";
	my $dhnd;
	if(opendir($dhnd, $path))
	{
		# add to the directory handle table - first find out
		# whether this client has a directory table and create it
		# if not.
		my $clientHandle=0;
		if(not defined $DIRHANDLE{$session})
		{
			my @hlist;
			$hlist[0]=$dhnd;
			$DIRHANDLE{$session}=\@hlist;
		}
		else
		{
			my $hlist=$DIRHANDLE{$session};
			my $laste=$#{@$hlist};
			for(my $i=0; $i <= $laste; $i++)
			{
				if(not defined $hlist->[$i])
				{
					$clientHandle=$i;
					$hlist->[$i]=$dhnd;
					last;
				}
			}
			
			# didn't find a hole? Add to the end
			if(!$clientHandle)
			{
				$clientHandle=$laste+1;
				$hlist->[$clientHandle]=$dhnd;
			}
				
		}
		print("Opendir: $message\n");
		sendMsg($session, 0x10, 0x00, pack("C", $clientHandle));
	}
	else
	{
		print("opendir failed for $message: $!");
		
		# todo: proper error code, but just ENOENT for now.
		sendMsg($session, 0x10, 0x02);
	}
}

# umount: closes a connection and frees all resources.
sub umount
{
	my ($session, $retry, $cmd, $message)=@_;

	delete $SESSION{$session};
	my $dirhandles=$DIRHANDLE{$session};
	if(defined($dirhandles))
	{
		foreach my $dhnd (@$dirhandles)
		{
			closedir($dhnd);
		}
		delete $DIRHANDLE{$session};
	}
	
	my $filehandles=$FILEHANDLE{$session};
	if(defined($filehandles))
	{
		foreach my $fhnd (@$filehandles)
		{
			close($fhnd);
		}
		delete $FILEHANDLE{$session}
	}
	delete $MOUNTPOINT{$session};
	sendMsg($session, 0x11, 0x00);	
}

# readdir: Reads the next directory entry.
sub readdir
{
	my ($session, $retry, $cmd, $message)=@_;

	# Retrieve the directory handle
	my $clientHandle=unpack("C", $message);
	my $dhnd=$DIRHANDLE{$session}->[$clientHandle];
	if(defined $dhnd)
	{
		if(my $dirent=readdir($dhnd))
		{
			sendMsg($session, 0x11, 0x00, "$dirent\x0");
		}
		else
		{
			# At EOF
			sendMsg($session, 0x11, 0x21);
		}
	}
	else
	{
		# Bad directory handle - EBADF
		sendMsg($session, 0x11, 0x06);
	}
}

# closedir: Close a directory and clean up resources.
sub closedir
{
	my ($session, $retry, $cmd, $message)=@_;

	# Retrieve the directory handle
	my $clientHandle=unpack("C", $message);
	my $dhnd=$DIRHANDLE{$session}->[$clientHandle];
	if(defined $dhnd)
	{
		closedir($dhnd);
		delete $DIRHANDLE{$session}->[$clientHandle];
		sendMsg($session, 0x12, 0x00);
	}
	else
	{
		# Bad directory handle - EBADF
		sendMsg($session, 0x12, 0x06);
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

