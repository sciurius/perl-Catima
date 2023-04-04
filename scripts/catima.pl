#!/usr/bin/perl

# Basic test for Catima module. Output should be the same as imput
# (except for compression).

use v5.36;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Catima;

my $verbose = 1;
my $book = Catima->new->load(shift);

for ( $book->passes ) {
    $_->print;
}

my %g = $book->groups;
while ( my ($k,$v) = each(%g) ) {
    print( "Group: $k, members: ", join(",",keys(%$v)), "\n");
}

$book->store("new.zip");
