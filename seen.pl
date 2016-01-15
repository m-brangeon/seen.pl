#!/usr/bin/perl -w
#manage kodi file librairy

use strict;
use File::Copy;
use 5.010;

my $databasepath="/home/kodi/.kodi/userdata/Database/MyVideos90.db";
my $moviepath="/root/video/";
my $exclude_ext='-not -name *.txt -not -name *.srt -not -name *.nfo -not -name *.html -not -name history -not -name *.cfg -not -name *.jpg -not -name *.png -not -name .bash.history';
my $exclude_dir='-name classique  -prune -o -name "dja_vu"  -prune -o -name film.glisse  -prune -o -name series -prune -o';
my @seenmovies=`sqlite3 $databasepath "select strFilename from files where playCount > 0";`;
my @movies=`find $moviepath $exclude_dir -type f $exclude_ext -printf "%f\n"`;

chomp @seenmovies;
chomp @movies;

sub usage() {
	say "Usage:";
	say "-d:	Dry-run";
	say "-h:	Print this help";
	exit 0
}

our $DRYRUN=0;

if (defined ($ARGV[0])){
	if ($ARGV[0] eq '-h') {
		usage();	
	} elsif ($ARGV[0] eq '-d') {
		$DRYRUN=1;
		say '=dry run=';
	}
}

sub is_serie($) {
	my ($film)=@_;

	if ($film =~ /s0[1-9]e[0-9]+/i) {
		return 1;
	}

	return 0
}

sub long_part_filename($) {
# take the 17 first character in name
#mandatory to avoid pollution in downloads naming
	my ($fullfile)=@_;
	my $file= substr($fullfile,0,17);
	
	return "$file";	
}

sub is_allready_seen($) {
	my ($filet)=@_;
	
	foreach (@seenmovies) {
		my $shrtned=long_part_filename("$_");
		if ("$filet" =~ /\Q$shrtned/) {
			return 1;
		}
	}

	return 0;
}

sub move_file($) {
	my ($fileu)=@_;
	#file can be in a subfolder, so we need to get the full realpath
	my $realpath=`find $moviepath -name "$fileu"`;
	chomp $realpath;

	if ("$realpath" eq '') { 
		say "can't fetch full path of $fileu";
	} else {
		my @rr=split('/', $realpath);
		my $parentp=$rr[-2];
	
		if (($parentp !~ 'video')&&($parentp !~ 'series')){
		#file is NOT at the root of librairy || root of series
			my @arrp=split(/\//,$realpath);
			$realpath=join "/",@arrp[0..(scalar(@arrp)-2)]; #will give everything except the filename
		}	

		if (is_serie($fileu)) {	
			if (! "$DRYRUN") { 
				move($realpath, '/root/video/serie/dja_vu/');
			} else {
				say "move $realpath to /root/video/serie/dja_vu";
			}
		} else {
			if (! "$DRYRUN") {
				move($realpath, '/root/video/dja_vu/');
			} else {
				say "move $realpath to /root/video/dja_vu";
			}
		}
	}
}

######### main ##########
#itterate all file in the movie folder
foreach (@movies) {
	my $short=long_part_filename($_);

	if (is_allready_seen($short)) {
		move_file($_);
	} else {
		next if (! "$DRYRUN");
		say "non-vu # $short # $_";
	}
}
