# Catima

Perl module to manipulate Catima loyalty passes.

The module provides two classes: `Catima` and `Pass`. 

## Basic operations

````
my $book = Catima->new;
my $pass = Pass->new( id => 1,
                      store => "MyCard",
                      barcodeid => 1234567890 );
$book->add($pass);
$book->store("new.zip");
````

## Tools

### `script/PassAndroid.pl`

Import a folder with passes from PassAndroid and creates `new.zip`
suitable for uploading to Android and import into the Catima app.

### `script/addpass.pl`

Create an update.zip containing a manually crafted pass.

A bit a WIP.

### `script/catima.pl`

A basic self test. Reads a catima zip and produces `new.zip` which is
the same as the input zip (except for compression levels).

## Requirements

`Object::Pad` version 0.78 or newer.

`Text::CSV_XS` version 1.50 or newer.

`Archive::Zip`.
