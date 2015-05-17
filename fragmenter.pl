use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Cookies::Mozilla;

my $make_req       = 1;
my $read_full_db   = 0;

my $page_start = 1;
my $page_end   = 46;

#3 months
#my $page_start = 560;
#my $page_end   = 600;

#6 months
#my $page_start = 1270;
#my $page_end   = 1346;

if ($read_full_db==1) {
	$page_start = 1;
	$page_end   = 2584;
}

my $path_to_cookies_mozilla = 'C:\Users\{user name}\AppData\Roaming\Mozilla\Firefox\Profiles\{some string}.default\cookies.sqlite'; #change the cookies path
my $user_agent = new LWP::UserAgent;
my $cookies    = HTTP::Cookies::Mozilla->new;
$cookies->load( $path_to_cookies_mozilla );
$user_agent->cookie_jar($cookies);


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year += 1900; 

my $res = "$year-$mon-$mday-$hour-$min-$sec";
open RESFILE, ">results-$res.txt";
if ($make_req==1) {
	if ($read_full_db==1) {
		open RAWFILE, ">full_db.txt";
	} else {
		open RAWFILE, ">raw_pages.txt";
	}

	for (my $i=$page_start; $i <= $page_end; $i++) {
		my $full_url = "http://fragmenter.net/fragments/all?page=$i";
		my $request  = new HTTP::Request('GET', $full_url);
		$cookies->add_cookie_header($request);
	
		#print RESFILE $request->as_string, "\n";	
		#print RESFILE "Set Cookie Jar?\n", $user_agent->cookie_jar->as_string, "\n";
		my $response   = $user_agent->request($request);
		print RAWFILE $response->{_content};
	}
	close RAWFILE;
}
if ($read_full_db==1) {
		open RAWFILE, "<full_db.txt";
	} else {
		open RAWFILE, "<raw_pages.txt";
	}
open( GREPFILE, ">grep_pages.txt" ) or die "$!";

while (<RAWFILE>) {
    if ( $_ =~ /<a href="\/users\// ) {
        print GREPFILE $_;
    }
}
close RAWFILE;
close GREPFILE;

open( GREPFILE, "<:encoding(UTF-8)", "grep_pages.txt" ) or die "$!";
open( SUBFILE,  ">sub_pages.txt" ) or die "$!";

my $line;
my $n = 1;
my %users_hash = ();
while (<GREPFILE>) {
	$line = $_;
    $line =~ s/<a href="\/users\//$n /;
    $line =~ s/">/ /;
	print SUBFILE $line;
	chomp;
    my @row = split( " ", $line );	
	$users_hash{$_}++ for $row[2];
	$n++;
}
close GREPFILE;
close SUBFILE;

my $size = keys %users_hash;
print RESFILE "Number of sectarians: $size pages: $page_start - $page_end\n";

foreach my $name (sort { $users_hash{$b} <=> $users_hash{$a} } keys %users_hash) {
    printf RESFILE "%-20s %s\n", $name, $users_hash{$name};
}	
close RESFILE;

