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
use Fcntl;
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
		0x12	=> \&closedir,
		0x20	=> \&openFile,
		0x21	=> \&readBlock,
		0x22	=> \&writeBlock,
		0x23	=> \&closeFile,
		0x24	=> \&statFile,
		0x25	=> \&seekFile,
		0x26	=> \&unlinkFile,
		0x27	=> \&chmodFile,
       		0x28	=> \&renameFile	);

# File modes
my %MODE=(	0x01	=> O_RDONLY,
		0x02	=> O_WRONLY,
		0x03	=> O_RDWR );

# Sessions - clients that have mounted us
my %SESSION;		# Table of session ids to IP addresses
my %LASTMSG;		# Table of last messages for a session
my %MOUNTPOINT;		# Table of mount points for sessions
my %DIRHANDLE;		# Table of directory handles
my %FILEHANDLE;		# Table of file handles
my %SEQNO;		# Table of sequence numbers

# Main program. Create the socket and listen for requests.
my $sock=IO::Socket::INET->new(LocalPort 	=> 16384,
			       Proto		=> 'udp')
	or die("Unable to create socket: $!");

my $msg;
my $port;
my $ipaddr;
my $hname;
while($sock->recv($msg, $MAXSIZE))
{
	($port, $ipaddr) = sockaddr_in($sock->peername);
	$hname=$sock->peerhost();

	my ($session, $retry, $cmd)=unpack("SCC", $msg);
	my $payload=substr($msg, 4);

	if($cmd != 0x00 && $ipaddr ne $SESSION{$session})
	{
		printf("$hname: Session ID %x invalid\n", $session);
		sendMsg(0x00, $cmd, 0xFF);
		next;
	}
	
	if(defined $TNFSCMDS{$cmd})
	{
		$SEQNO{$session}=$retry;
		$TNFSCMDS{$cmd}->($session, $retry, $cmd, $payload);
	}
	else
	{
		# reply ENOSYS 'operation not implemented'
		printf("$hname: Operation %x not implemented\n", $cmd);
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
	$SEQNO{$session}=$retry;

	# convert path
	$mountpoint=$root . $mountpoint;

	# check the mount point actually exists
	if(opendir(DHND, $mountpoint))
	{
		closedir(DHND);
		$SESSION{$session}=$ipaddr;
		$MOUNTPOINT{$session}=$mountpoint;

		print("Mount: $mountpoint from $hname\n");
		sendMsg($session, 0x00, 0x00, "\x00\x01\x00\x00");
	}
	else
	{
		# session is null, cmd is 0, error is ENOENT (0x02)
		# version is 1.0
		print("Mount: FAILED for $mountpoint from $hname\n");
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
		print("Opendir: $message from $hname\n");
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

	# tell the client we're done before deleting
	# the important stuff needed to actually return the msg...
	sendMsg($session, 0x01, 0x00);	

	delete $SESSION{$session};
	delete $SEQNO{$session};
	delete $MOUNTPOINT{$session};
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

# openFile: Open a file.
sub openFile
{
	my ($session, $cmd, $status, $msg)=@_;
	my ($filemode, $fileflags)=unpack("CC", $msg);
	my $filename=substr($msg, 2);
	$filename =~ s/\x0//g;
	my $path="$MOUNTPOINT{$session}" . $filename;
	print("Open request: $path from $hname\n");

	# use sysopen to do, well, a sysopen.
	my $fhnd;
	if(sysopen($fhnd, $path, $MODE{$filemode} | getOpenFlags($fileflags)))
	{
		# add to the file handle table - first find out
		# whether this client has a directory table and create it
		# if not.
		my $clientHandle=0;
		if(not defined $FILEHANDLE{$session})
		{
			my @hlist;
			$hlist[0]=$fhnd;
			$FILEHANDLE{$session}=\@hlist;
		}
		else
		{
			my $hlist=$FILEHANDLE{$session};
			my $laste=$#{@$hlist};
			for(my $i=0; $i <= $laste; $i++)
			{
				if(not defined $hlist->[$i])
				{
					$clientHandle=$i;
					$hlist->[$i]=$fhnd;
					last;
				}
			}
			
			# didn't find a hole? Add to the end
			if(!$clientHandle)
			{
				$clientHandle=$laste+1;
				$hlist->[$clientHandle]=$fhnd;
			}
				
		}
		print("Handle=$clientHandle\n");
		sendMsg($session, 0x20, 0x00, pack("C", $clientHandle));

	}
	else
	{
		my $err=int($!);
		sendMsg($session, 0x20, $err);
	}
}

# readBlock - Reads from an open file handle.
sub readBlock
{
	my ($session, $cmd, $status, $msg)=@_;
	
	my ($clientHandle, $szlsb, $szmsb)=unpack("CCC", $msg);
	my $blocksize=($szmsb*256)+$szlsb;
	my $fhnd=$FILEHANDLE{$session}->[$clientHandle];
	if(defined $fhnd)
	{
		my $block;
		my $bytes=sysread($fhnd, $block, $blocksize);
		if($bytes > 0)
		{
			my $msg=pack("CC", $bytes%256, int($bytes/256)) .
				$block;
			sendMsg($session, 0x21, 0x00, $msg);
		}
		elsif($bytes == 0)
		{
			sendMsg($session, 0x21, 0x21);	# EOF
		}
		else
		{
			# send errno
			sendMsg($session, 0x21, int($!));
		}
	}
	else
	{
		# Bad file handle - EBADF
		sendMsg($session, 0x21, 0x06);
	}
	
}

# write - Writes to an open file handle.
sub writeBlock
{
	my ($session, $cmd, $status, $msg)=@_;

	my ($clientHandle, $szlsb, $szmsb)=unpack("CCC", $msg);
	my $blocksize=($szmsb*256)+$szlsb;
	my $block=substr($msg, 3);
	my $fhnd=$FILEHANDLE{$session}->[$clientHandle];
	if(defined $fhnd)
	{
		my $bytes=syswrite($fhnd, $block, $blocksize);
		if($bytes > 0)
		{
			my $msg=pack("CC", $bytes%256, int($bytes/256)) .
				$block;
			sendMsg($session, 0x22, 0x00, $msg);
		}
		else
		{
			# send errno
			sendMsg($session, 0x22, int($!));
		}
	}
	else
	{
		# Bad file handle - EBADF
		sendMsg($session, 0x21, 0x06);
	}
}

# close - Closes an open file handle.
sub closeFile
{
	my ($session, $cmd, $status, $msg)=@_;

	# Retrieve the file handle
	my $clientHandle=unpack("C", $msg);
	my $fhnd=$FILEHANDLE{$session}->[$clientHandle];
	if(defined $fhnd)
	{
		print("Closed handle $clientHandle\n");
		close($fhnd);
		delete $FILEHANDLE{$session}->[$clientHandle];
		sendMsg($session, 0x23, 0x00);
	}
	else
	{
		# Bad file handle - EBADF
		sendMsg($session, 0x23, 0x06);
	}

}

# seekFile - Seeks to a location in a file. (Command 0x25)
sub seekFile
{
	my ($session, $cmd, $status, $msg)=@_;
	
	my ($clientHandle, $seektype, $seekloc)=unpack("CCV", $msg);
	if($seekloc & 8000000)
	{
		$seekloc = -$seekloc;
	}
	#print("seekFile: handle=$clientHandle type=$seektype loc=$seekloc\n");
	my $fhnd=$FILEHANDLE{$session}->[$clientHandle];
	if(defined $fhnd)
	{
		# this assumes posix definitions of SEEK_CUR, SYS_END etc.
		if(sysseek($fhnd, $seekloc, $seektype))
		{
			# success
			printf("Seek OK - seeking %x bytes type %d\n",
				$seekloc, $seektype);
			sendMsg($session, 0x25, 0x00);
		}
		else
		{
			print("Oops: $!\n");
			sendMsg($session, 0x25, int($!));
		}
	}
	else
	{
		# send EBADF
		sendMsg($session, 0x25, 0x06);
	}
}

# statFile - gets information on a file.
sub statFile
{
	my ($session, $cmd, $status, $msg)=@_;
	
	# the message contains the file to stat, remove the terminator
	$msg=~s/\x00//g;
	my $filename=$MOUNTPOINT{$session} . $msg;
	print("Statting $filename from $hname\n");
	if(my @st=stat($filename))
	{
		# perms in big endian, rest in "vax order" - little
		# endian. (See perldoc for "pack")
		my $smsg=pack("vvvVVVV", $st[2], $st[4], $st[5],
				$st[7], $st[8], $st[9], $st[10]);
		$smsg .= getpwuid($st[4]) . "\x0" . getgrgid($st[5]) . "\x0";
		sendMsg($session, 0x24, 0x00, $smsg);
		
	}
	else
	{
		# send error number
		sendMsg($session, 0x24, int($!));
	}
}

# unlinkFile - Unlinks a file (cmd 0x26)
sub unlinkFile
{
	my ($session, $cmd, $status, $msg)=@_;

	# remove terminator and create the path	
	$msg=~s/\x00//g;
	my $filename=$MOUNTPOINT{$session} . $msg;
	if(unlink $filename)
	{
		sendMsg($session, 0x26, 0x00);
	}
	else
	{
		sendMsg($session, 0x26, int($!));
	}
}

# chmodFile - Changes perms on a file (cmd 0x27)
sub chmodFile
{
	my ($session, $cmd, $status, $msg)=@_;

	# remove terminator and create the path	
	$msg=~s/\x00$//g;
	my ($perm, $filename)=unpack("vA", $msg);
	$filename=$MOUNTPOINT{$session} . $filename;
	if(chmod($perm, $filename))
	{
		sendMsg($session, 0x27, 0x00);
	}
	else
	{
		sendMsg($session, 0x27, int($!));
	}
}

# renameFile - moves a file within the filesystem (0x28)
sub renameFile
{
	my ($session, $cmd, $status, $msg)=@_;

	# separate out "from" and "to" paths.
	my ($from, $to)=split(/\x00/, $msg);
	$from = $MOUNTPOINT{$session} . $from;
	$to = $MOUNTPOINT{$session} . $to;
	print("rename: $from => $to\n");
	if(rename($from, $to))
	{
		sendMsg($session, 0x28, 0x00);
	}
	else
	{
		sendMsg($session, 0x28, int($!));
	}
}

sub sendMsg
{
	my ($session, $cmd, $status, $msg)=@_;
	my $seq=$SEQNO{$session};
#	print("message: Session $session cmd $cmd status $status seq $seq\n");
	my $dgram=pack("SCCC", $session, $seq, $cmd, $status);
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

#---------------------------------------------------------------------------
# Miscellaneous functions
# getOpenFlags: convert tnfs flags to flags for open.
sub getOpenFlags
{
	my $flags=0;
	my $tf=shift;

	if($tf & 0x01) { $flags |= O_APPEND; }
	if($tf & 0x02) { $flags |= O_CREAT; }
	if($tf & 0x04) { $flags |= O_EXCL; }
	if($tf & 0x08) { $flags |= O_TRUNC; }
	return $flags;
}

