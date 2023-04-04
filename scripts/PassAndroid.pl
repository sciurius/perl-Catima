#!/usr/bin/perl

use v5.36;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Catima;

my $verbose = 1;
my $book = Catima->new;

my $pd = shift;
-d $pd or die("$pd: no directory\n");

use JSON::PP;
my $pp = JSON::PP->new->utf8;

opendir( my $dh, $pd );
my @passes = grep { ! /^\./ } readdir($dh);
close($dh);

warn("Number of passes = ", scalar(@passes), "\n") if $verbose;

my $id = 1;
my $time = time;

foreach my $pass ( @passes ) {
    my $path = "$pd/$pass";
    unless ( -s "$path/main.json" ) {
	warn("$pass: No JSON data?\n");
	next;
    }
    open( my $fh, '<', "$path/main.json" )
      or die("$path/main.json: $!\n");
    my $info = $pp->decode(join("",<$fh>));

    my $p = Pass->new( id => $id++,
		       store => $info->{description},
		       cardid => $info->{barCode}->{message} // $info->{description},
		       barcodetype => $info->{barCode}->{format},
		       headercolor => (hex(substr($info->{accentColor},3))) - 2**24,
		       lastused => $time,
		     );

    for ( qw( front back logo ) ) {
	if ( -s "$path/$_.png" ) {
	    open( my $fd, '<:raw', "$path/$_.png" )
	      or die("$path/$_.png: $!\n");
	    undef $/;
	    my $mut = $_ eq "logo" ? "iconimg" : "${_}img";
	    $p->$mut = scalar(<$fd>);
	    close($fd);
	}
    }

    
    if ( -s "$path/logo.png" ) {
	open( my $fd, '<:raw', "$path/logo.png" )
	  or die("$path/logo.png: $!\n");
	undef $/;
	$p->frontimg = scalar(<$fd>);
	close($fd);
    }
    if ( -s "$path/strip.png" ) {
	open( my $fd, '<:raw', "$path/strip.png" )
	  or die("$path/strip.png: $!\n");
	undef $/;
	$p->backimg = scalar(<$fd>);
	close($fd);
    }
    $book->add($p);
}


for ( $book->passes ) {
    $_->print;
}

my %g = $book->groups;
while ( my ($k,$v) = each(%g) ) {
    print( "Group: $k, members: ", join(",",keys(%$v)), "\n");
}

$book->store("new.zip");
