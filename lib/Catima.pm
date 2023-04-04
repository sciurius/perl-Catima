#!/usr/bin/perl

use v5.36;
use Object::Pad ':experimental(init_expr)';

class Catima {

    my $version = 2;

    use Archive::Zip qw( :CONSTANTS :ERROR_CODES );

    field @passes :reader;
    field %groups :reader;
    field @groups;		# for order
    field $sort :param { undef };

    my @imagetypes = qw( icon front back );

    method load($file) {

	use File::LoadLines;

	# Get the catima.csv from the zip.
	my $zip = Archive::Zip->new;
	unless ( $zip->read($file) == AZ_OK ) {
	    die("$file: read error\n");
	}
	use Archive::Zip::MemberRead;
	my $fh = Archive::Zip::MemberRead->new( $zip, "catima.csv" );

	# Check version.
	my $line = $fh->getline;;
	die("version should be \"$version\"\n")
	  unless $line == $version;
	$line = $fh->getline;
	die("2nd line should be empty, not '$line'\n")
	  unless $line !~ /\S/;

	# Parse the three CSV segments.
	my $res = parse_csv($fh);

	# CSV 1: Groups
	for ( @{ $res->{csv1} } ) {
	    push( @groups, $_->{_id} );
	    $groups{$_->{_id}} = {};
	}

	# CSV 2: Passes.
	for ( @{ $res->{csv2} } ) {
	    my %atts = %$_;
	    $atts{id} = delete( $atts{_id} );
	    my $pass = Pass->new(%atts);

	    my $id = $pass->id;
	    for ( @imagetypes ) {
		if ( my $m = $zip->memberNamed( $pass->imagename($_) ) ) {
		    my $mut = "${_}img";
		    $pass->$mut = $zip->contents($m);
		}
	    }

	    push( @passes, $pass );
	}

	if ( $sort ) {
	    if ( $sort eq "id" ) {
		# Sort on ID.
		@passes = sort { $a->id <=> $b->id } @passes;
	    }
	    elsif ( $sort eq "title" ) {
		# Sort on note
		@passes = sort { $a->note cmp $b->note } @passes;
	    }
	    else {
		die("Unsupported sort mode: ", $sort, "\n");
	    }
	}

	# CSV 3: group membership table.
	for ( @{ $res->{csv3} } ) {
	    $groups{$_->{groupId}}{$_->{cardId}} = 1;
	}

	# Return self for chaining.
	$self;
    }


    sub parse_csv($fh) {

	# Parse CSV segments.
	use Text::CSV_XS 1.50 qw(csv);

	my %res;
	my $sct = "csv1";
	my @headers;

	csv( in    => $fh,
	     out   => undef,
	     on_in => sub {
		 if ( @{$_[1]} == 1 && $_[1][0] eq "" ) {  # empty row
		     @headers = ();
		     $sct++;
		     return;
		 }
		 unless ( @headers ) {
		     @headers = @{$_[1]};
		     return;
		 }
		 my %r; @r{@headers} = @{$_[1]};
		 push( @{$res{$sct}} => \%r );
	     },
	   );
	\%res;
    }

    method add($pass) {
	push( @passes, $pass );
	# Return self for chaining.
	$self;
    }

    sub _csv($d) {
	return "" if ($d // "") eq "";
	my $r = $d;
	$r =~ s/"/""/g;
	$r = qq{"$r"} if $r =~ /[",]/;
	$r;
    }

    method store($file) {
	my $zip = Archive::Zip->new;

	my $csv = "$version\n";
	$csv .= "\n_id\n";
	for ( keys %groups ) {
	    $csv .= $_ . "\n";
	}
	$csv .= "\n";
	my @fn = Pass->fieldnames;
	$csv .= "_" . join( ",", @fn ) . "\n";
	for my $pass ( @passes ) {
	    warn("Export: ", $pass->id, "\n");
	    $csv .= _csv( $pass->$_ ) . "," for @fn;
	    chop($csv);
	    $csv .= "\n";

	    for ( @imagetypes ) {
		my $mut = "${_}img";
		if ( my $m = $pass->$mut ) {
		    # No need to compress png and jpg.
		    $zip->addString( { string => $m,
				       zipName => $pass->imagename($_),
				     } );
		}
	    }
	}

	$csv .= "\n";
	$csv .= join( ",", qw( cardId groupId ) ) . "\n";
	for my $group ( @groups ) {
	    for ( keys %{$groups{$group}} ) {
		$csv .= join( ",", _csv($_), _csv($group) ) . "\n"
	    }
	}

	# Make CRLF data.
	$csv =~ s/\n/\r\n/g;
	$zip->addString( { string => $csv,
			   zipName => "catima.csv",
			   compressionMethod => COMPRESSION_DEFLATED,
			   compressionLevel => COMPRESSION_LEVEL_DEFAULT,
			 } );

	unless ( $zip->writeToFileNamed($file) == AZ_OK ) {
	    die("$file: write error\n");
	}
    }
}

class Pass {

    field $_id		:reader  :param;
    field $store	:reader  :param;
    field $note		:reader  :param //= undef;
    field $validfrom	:reader  :param //= undef;
    field $expiry	:reader  :param //= undef;
    field $balance	:reader  :param //= 0;
    field $balancetype	:reader  :param //= undef;
    field $cardid	:reader  :param //= undef;
    field $barcodeid	:reader  :param //= undef;
    field $barcodetype	:reader  :param //= undef;
    field $headercolor	:reader  :param //= undef;
    field $starstatus	:reader  :param //= 0;
    field $lastused	:reader  :param //= undef;
    field $archive	:reader  :param //= 0;
    field $frontimg     :mutator :param //= undef;
    field $backimg      :mutator :param //= undef;
    field $iconimg      :mutator :param //= undef;

    method fieldnames :common () {
	qw( id store note validfrom expiry
	    balance balancetype
	    cardid barcodeid barcodetype
	    headercolor starstatus lastused archive );
    }

    method imagename($img, $type = "png" ) {
	"card_${_id}_$img.$type";
    }

    # Quick and dirty show pass content.
    method print() {
	print( "Pass $_id: \"$store\"" );
	print( ", note: \"$note\"" ) if $note;

	print( ", validfrom: ", isodate($validfrom/1000) ) if $validfrom;
	print( ", expiry: ", isodate($expiry/1000) ) if $expiry;

	print( ", balance: $balance" ) if $balance;
	print( ", balancetype: $balancetype" ) if $balancetype;

	print( ", cardID: ", $cardid//"" );
	print( ", barcode: ", ($barcodeid//"")eq""?($cardid//""):$barcodeid );

	printf( ", colour: %6x", $headercolor&0xffffff);
	print( ", fav" ) if $starstatus;
	print( ", used: " . isodate($lastused,1) );
	print( ", archived" ) if $archive;

	print( "\n");
    }

    # Format ISO date with optional time.
    sub isodate( $t, $full = 0 ) {
	return "" unless $t;
	my @tm = localtime($t);
	sprintf( "%04d-%02d-%02d",
		 1900+$tm[5], 1+$tm[4], $tm[3] ) .
	( $full ? sprintf( " %02d:%02d:%02d", @tm[2,1,0] ) : "" );
    }
}

package Catima;

1;
