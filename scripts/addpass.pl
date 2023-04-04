#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Sun Sep 15 18:39:01 1996
# Last Modified By: 
# Last Modified On: Tue Apr  4 17:21:33 2023
# Update Count    : 53
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Object::Pad;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Catima;

# Package name.
my $my_package = 'Sciurix';
# Program name and version.
my ($my_name, $my_version) = qw( addpass 0.01 );

################ Command line parameters ################

use Getopt::Long 2.13;

# Command line options.
my %params = ( id => 1, starstatus => 0, archive => 0 );
my %images;
my $verbose = 1;		# verbose processing
my $output = "update.zip";

# Development options (not shown with -help).
my $debug = 0;			# debugging
my $trace = 0;			# trace (show process)
my $test = 0;			# test mode.

# Process command line options.
app_options();

# Post-processing.
$trace |= ($debug || $test);

################ Presets ################

my $TMPDIR = $ENV{TMPDIR} || $ENV{TEMP} || '/usr/tmp';

################ The Process ################

my $pass = Pass->new(%params);

for ( qw( icon front back ) ) {
    next unless $images{$_};
    die("$images{$_}: $!\n") unless -s $images{$_};
    my $data = do { open( my $fd, '<:raw', $images{$_} ); undef $/; <$fd> };
    my $method = $_ . "img";
    $pass->$method = $data;
}

my $book = Catima->new;
$book->add($pass);
$book->store($output);

exit 0;

################ Subroutines ################

sub app_options {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally
    my $man = 0;		# handled locally

    my $pod2usage = sub {
        # Load Pod::Usage only if needed.
        require Pod::Usage;
        Pod::Usage->import;
        &pod2usage;
    };

    # Process options.
    if ( @ARGV > 0 ) {
	GetOptions( "note=s"        => \$params{note},
		    "description=s" => \$params{note},
		    "validfrom=s"   => \$params{validfrom},
		    "expiry=s"      => \$params{expiry},
		    "balance=f"     => \$params{balance},
		    "balancetype=s" => \$params{balancetype},
		    "cardid=s"      => \$params{cardid},
		    "code=s"        => \$params{barcodeid},
		    "barcodeid=s"   => \$params{barcodeid},
		    "barcodetype=s" => \$params{barcodetype},
		    "headercolor=s" => \$params{headercolor},
		    "favorite"      => \$params{starstatus},
		    "favourite"     => \$params{starstatus},
		    "lastused=s"    => \$params{lastused},
		    "archive"       => \$params{archive},
		    "frontimg=s"    => \$images{front},
		    "backimg=s"     => \$images{back},
		    "iconimg=s"     => \$images{icon},
		    "output=s"      => \$output,
		    'ident'	    => \$ident,
		    'verbose+'	    => \$verbose,
		    'quiet'	    => sub { $verbose = 0 },
		    'trace'	    => \$trace,
		    'help|?'	    => \$help,
		    'man'	    => \$man,
		    'debug'	    => \$debug )
	  and @ARGV==1 or $pod2usage->( -exitval => 2, -verbose => 0 );
    }
    $params{store} = $ARGV[0];
    if ( $ident or $help or $man ) {
	print STDERR ("This is $my_package [$my_name $my_version]\n");
    }
    if ( $man or $help ) {
	$pod2usage->( -exitval => 0, -verbose => $man ? 2 : 0 );
    }
}

__END__

################ Documentation ################

=head1 NAME

addpass - add a pass to Catima

=head1 SYNOPSIS

addpass [options] name

=head1 OPTIONS

=over 8

=item B<--description=>I<XXX>  B<--note=>I<XXX>

A description.

=item B<--validfrom=>I<XXX>

Pass field.

=item B<--expiry=>I<XXX>

Pass field.

=item B<--balance=>I<NNN>

Pass field.

=item B<--balancetype=>I<XXX>

Pass field.

=item B<--cardid=>I<XXX>

Pass field.

=item B<--code=>I<XXX>  B<--barcodeid=>I<XXX>

The information to be encoded in the barcode.

=item B<--barcodetype=>I<XXX>

One of the values
C<AZTEC>, C<CODABAR>, C<CODE_39>, C<CODE_93>, C<CODE_128>,
C<DATA_MATRIX>, C<EAN_8>, C<EAN_13>, C<ITF>, C<PDF_417>,
C<QR_CODE>, C<UPC_A>, and C<UPC_E>.

=item B<--headercolor=>I<XXX>

Pass field.

=item B<--favourite>

Pass is a favourite.

=item B<--lastused=>I<XXX>

Pass field.

=item B<--archive>

Pass has been archived.

=item B<--frontimg=>I<XXX>

Name of a C<PNG> image to be used as front image.

=item B<--backimg=>I<XXX>

Name of a C<PNG> image to be used as back image.

=item B<--iconimg=>I<XXX>

Name of a C<PNG> image to be used as icon image.

=item B<--output=>I<XXX>

The name of the output zip.

Default is C<update.zip>.

=item B<--help>

Prints a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=item B<--ident>

Prints program identification.

=item B<--verbose>

Provides more verbose information.
This option may be repeated to increase verbosity.

=item B<--quiet>

Suppresses all non-essential information.

=back

=head1 DESCRIPTION

B<This program> will create a zip file containing a Catima pass that
can be uploaded to Android and imported into the Catima app.

The identifying name for the pass is the only argument required.
Everything else is optional.

=cut

