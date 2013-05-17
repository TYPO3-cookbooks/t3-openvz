#!/usr/bin/perl

###############################################################################
# vzstats.pl
#
# this script reads /proc/user_beancounters on openvz HNs and VEs and displays
# the values in human-readable format (megabytes/kilobytes).
#
# The script can be distributed freely for everybody who finds it usable.
#
# Christian Anton <mail |_at_| christiananton.de> 2008-09-18
#
# David Osborn <ossdev -at- daoCon.com> 2008-11-09
#     Added VE name to output


open(BEANS,"/proc/user_beancounters");
chomp ($arch = `uname -m`);

sub check_maxulong {
	my $number = shift;

	if ($arch eq "x86_64") {
		if ($number == 9223372036854775807) {
			return 1;
		} else {
			return undef;
		}
	} else {
		if ($number == 2147483647) {
			return 1;
		} else {
			return undef;
		}
	}
}

sub recalc_bytes {
	my $bytes = shift;

	if (defined(&check_maxulong($bytes))) { return "MAX_ULONG"; }

	my $kbytes = $bytes / 1024;
	my $ret;

	# if over 1mb, show mb values
	if ($kbytes > 1024) {
		my $mbytes = $kbytes / 1024;
		$ret = sprintf("%.2f", $mbytes) . " mb";
		return $ret;
	} else {
		$ret = sprintf("%.2f", $kbytes) . " kb";
		return $ret;
	}
}

sub recalc_pages {
	my $pages = shift;

	if ($pages == 0) { return "0"; }
	if (defined(&check_maxulong($pages))) { return "MAX_ULONG"; }

	my $kbytes = $pages * 4;
	my $ret;

	if ($kbytes > 1024) {
		my $mbytes = $kbytes / 1024;
		$ret = sprintf("%.2f", $mbytes) . " mb";
		return $ret;
	} else {
		$ret = sprintf("%.2f", $kbytes) . " kb";
		return $ret;
	}
}

sub recalc_nothing {
	my $number = shift;
	if (defined(&check_maxulong($number))) { return "MAX_ULONG"; }

	return $number;
}

sub printline {
	my $mode = shift; # 0=normal, 1=bytes, 2=pages
	my $ident = shift;
	my $held = shift;
	my $maxheld = shift;
	my $barrier = shift;
	my $limit = shift;
	my $failcnt = shift;

	if ($mode == 0) {
		printf ("%-15s",$ident);
		printf ("%18s",&recalc_nothing($held));
		printf ("%21s",&recalc_nothing($maxheld));
		printf ("%21s",&recalc_nothing($barrier));
		printf ("%21s",&recalc_nothing($limit));
		printf ("%21s",$failcnt);
		print "\n";
	} elsif ($mode == 1) {
		printf ("%-15s",$ident);
		printf ("%18s",&recalc_bytes($held));
		printf ("%21s",&recalc_bytes($maxheld));
		printf ("%21s",&recalc_bytes($barrier));
		printf ("%21s",&recalc_bytes($limit));
		printf ("%21s",$failcnt);
		print "\n";
	} elsif ($mode == 2) {
		printf ("%-15s",$ident);
		printf ("%18s",&recalc_pages($held));
		printf ("%21s",&recalc_pages($maxheld));
		printf ("%21s",&recalc_pages($barrier));
		printf ("%21s",&recalc_pages($limit));
		printf ("%21s",$failcnt);
		print "\n";
	}
}

sub work_line {
	my $line = shift;
	my $ident = $line;
	my $held = $line;
	my $maxheld = $line;
	my $barrier = $line;
	my $limit = $line;
	my $failcnt = $line;



	$ident =~ s/^\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/$1/;
	$held =~ s/^\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/$2/;
	$maxheld =~ s/^\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/$3/;
	$barrier =~ s/^\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/$4/;
	$limit =~ s/^\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/$5/;
	$failcnt =~ s/^\s+(\w+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/$6/;

	# 0=normal, 1=bytes, 2=pages
	if ($ident eq "dummy") {
		# do nothing, skip this line
	} elsif ($ident =~ /pages/) {
		&printline(2,$ident,$held,$maxheld,$barrier,$limit,$failcnt);
	} elsif ($ident =~ /^num/) {
		&printline(0,$ident,$held,$maxheld,$barrier,$limit,$failcnt);
	} else {
		&printline(1,$ident,$held,$maxheld,$barrier,$limit,$failcnt);
	}

}

sub print_header {
	my $uid = shift;
	my $hostname = shift;

	print "#####################################################################################################################\n";
	print "BEANS FOR UID $uid ($hostname)\n";
	print "resource                     held              maxheld              barrier                limit              failcnt\n";
}

sub get_hostname {
	my $uid = shift;
	my @vzout;

	# already retrieved list
	if (defined %hostnames) {
		if (defined $hostnames{$uid}) {
			return $hostnames{$uid};
		} else {
			return 'not found';
		}
	# try to retrieve the list
	} elsif ( eval(@vzout = `vzlist -H -o veid,hostname`) ) {
		$hostnames{0} = 'HN';
		while (@vzout) {
			my $line = shift @vzout;
			my ($tuid,$hostname) = $line =~ /^\s+(\d+)\s+(\S+)/;
			$hostnames{$tuid} = $hostname;
		}
		return $hostnames{$uid};
	} else {
		# something's wrong
		return 'unknown';
	}

}


# Hash used to store uid to hostname lookups
my %hostnames;

# now eat your beans baby
while (<BEANS>) {
	chomp($line = $_);

	# skip processing of headline
	if ($line =~ /^\s+uid/) {
		# do nothing, skip this
	} elsif ($line =~ /^Ver/) {
		# do nothing, skip this
	} elsif ($line =~ /^\s+\d+:\s+kmem/) {
		$uid = $line;
		$line =~ s/^(\s+)(\d+):/$1/;
		$uid =~ s/^(\s+)(\d+):.*$/$2/;
		&print_header($uid, get_hostname($uid));
		&work_line($line);
	} else {
		&work_line($line);
	}
}

close(BEANS);
