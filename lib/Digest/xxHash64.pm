package Digest::xxHash64;
use strict;
use Math::Int64;
require XSLoader;

require Exporter;
our @ISA = qw(Exporter);

use vars qw($VERSION);

BEGIN {
    $VERSION = 1.02;
    XSLoader::load(__PACKAGE__, $VERSION);
}

our @EXPORT_OK = qw(xxHash64 xxHash64hex);

1;
__END__

=head1 NAME

Digest::xxHash64 - Perl interface implementation to xxHash 64 bit algorithm

=head1 SYNOPSIS

    # Object oriented style interface

    use Digest::xxHash64;

    my $xx = Digest::xxHash64->new;

    $xx->add($data1, $data2, $data3);
    $xx->add($data4);
    $xx->addfile($file_hadle);
    $xx->addfile($another_file_hadle, $read_length);

    my $hash64 = $xx->digest();
    my $hash64_hex = $xx->hexdigest();

    $xx->reset($seed);
    $xx->add($data5);
    my $another_hash64 = $xx->digest();
    my $another_hash64_hex = $xx->hexdigest();



    # Functional style interface

    use Digest::xxHash64 qw[ xxHash64  xxHash64hex ];

    my $hash64 = xxHash64($data);
    my $hash64_hex = xxHash64hex($data);

    my $hash64 = xxHash64($data, $seed);
    my $hash64_hex = xxHash64hex($data, $seed);



=head1 DESCRIPTION

xxHash is an extremely fast non-cryptographic hash algorithm, working
at speeds close to RAM limits. It is proposed in two flavors, 32 and 64 bits, producing
32 bit or 64 bit long digest output, respectively. (See http://www.xxhash.com for details)
This module is an object oriented interface of xxHash 64-bit hash functions.
The interface implementation can handle data of arbitrary length and
capable to run both on 32 bit and 64 bit Perl environment.


=head1 OBJECT ORIENTED STYLE INTERFACE


The object oriented interface of C<Digest::xxHash64> is described in this
section.  After a C<Digest::xxHash64> object has been created, you will add
data to it (once or several times) and finally ask for the digest in a suitable format.
A single object can be used to calculate multiple digests.
Error handling is provided by croak() in all method.


The following methods are provided:

=over 4


=item $xx = Digest::xxHash64->new([$seed])

The constructor returns a new C<Digest::xxHash64> object which encapsulate
the state of the xxHash 64 bit digest algorithm.

If called as an instance method (i.e. $xx->new) a new object is created and returned in this case.

$seed is an optional argument. This is the seed parameter of the algorithm and being a
max 64 bit integer. Seed can be used to alter the result predictably.
If omitted zero is assumed.



=item $xx->reset([$seed])

Resets object's internal state.

$seed is an optional argument. This is the seed
parameter of the algorithm itself and being a max 64bit integer value. Seed can be used
to alter the digest result predictably. If omitted zero is assumed.


=item $xx->clone

Create and return a copy of the $xx object as Digest::xxHash64 in its actual state.
It is useful when you do not want to destroy the digests state,
but need an intermediate value of the
digest, e.g. when calculating digests iteractively on a continuous data
stream.  Example:

    my $xx = Digest::xxHas64->new;
    open($FH, '<', 'myfile.bin');
    binmode($FH);
    while (read($FH, $buffer, 4096)) {
      $xx->add($buffer);
      print "hash so far: $.: ", $xx->clone->hash_hex, "\n";
    }


=item $xx->add($data,...)

The $data provided as argument are appended to the byte sequence we
calculate the digest for.  The return value is the number of bytes added.

All these lines will have the same effect on the state of the $xx
object:

    $xx->add("a"); $xx->add("b"); $xx->add("c");
    $xx->add("ab"); $xx->add("c");
    $xx->add("a", "b", "c");
    $xx->add("abc");


=item $xx->addfile($io_handle, [$len_to_read])

The file represented by C<$io_handle> will be read from its current position until EOF and
its content appended to the
byte sequence we calculate the digest for.  The return value is the number
of bytes added. The optional C<$len_to_read> argument specifies the maximal
data amount to read from the file. So making possible to calculate digest based only on a portion of the file.
The return value shows if EOF happend before reading as much data. In such a case,
return value is less than C<$len_to_read>.

The C<addfile()> method will croak() if it fails reading data for some
reason other than EOF. If it croaks it is unpredictable what the state of the $xx
object will be in. The addfile() method might have been able to read
the file partially before it failed. It is probably wise to discard
or reset the $xx object if this occurs or to clone before to revert to original state.

In most cases you want to make sure that the $io_handle is in
binmode before you pass it as argument to the C<addfile()> method.


=item $xx->digest

Return the binary digest for the previously added data. The returned number is a 64 bit unsigned integer.
It is useful when to store the digest into database field directly as a number.
Under 32 bit Perl environment you have to use Math::Int64 module to handle this type of numbers.

Note that the C<digest> operation is effectively a destructive,
read-once operation. Once it has been performed, the C<Digest::xxHash64>
object state is automatically finalized and need to call C<reset> method to be used to calculate another
digest value for another data. Call $xx->clone->digest if you want to calculate the
digest without resetting the digest state.


=item $xx->hexdigest

Same as $xx->digest, but will return the digest in hexadecimal
form. The length of the returned string will be 16 and it will only
contain characters from this set: '0'..'9' and 'A'..'F'.

=back


=head1 FUNCTIONAL STYLE INTERFACE

The following functions are provided by the C<Digest::xxHash64> module.
None of these functions are exported by default.
Error handling is provided by croak() in all method.

=over 4


=item xxHash64($data, [$seed])

Return the binary digest for the data argument. The returned number is a 64 bit unsigned integer.
Under 32 bit Perl environment you have to use Math::Int64 module to handle this type of numbers.
$seed is an optional argument. This is the seed parameter of the algorithm and being a
max 64 bit integer. Seed can be used to alter the result predictably.
If omitted zero is assumed.


=item xxHash64hex($data, [$seed])

Same as xxHash64() function, but will return the digest in hexadecimal form. The
length of the returned string will be 16 and it will only contain
characters from this set: '0'..'9' and 'A'..'F'.


=back



=head1 EXAMPLES

To calculate digest of 3 separate strings as one concatenated string in OO style:

    use Digest::xxHash64;

    $xx = Digest::xxHash64->new;
    $xx->add('foo', 'bar');
    $xx->add('baz');
    $xx = $xx->hexdigest;

    print "Digest is $digest\n";

With OO style, you can break the input data arbitrarily.  This means that we
are not limited to have space for the whole input data in memory, i.e.
we can handle input data of any size.

This is useful when calculating checksum for files or network streams:

    use Digest::xxHash64;

    my $filename = __FILE__;
    open (my $FH, '<', $filename) or die "Can't open '$filename': $!";
    binmode($FH);

    my $xx = Digest::xxHash64->new;
    while (read($FH, $buffer, 4096)) {
        $xx->add($buffer);
    }
    close($FH);
    print $xx->hexdigest, '  ', $filename, "\n";

Or we can use the addfile method for more efficient reading of the file:

    use Digest::xxHash64;

    my $filename = __FILE__;
    open (my $FH, '<', $filename) or die "Can't open '$filename': $!";
    binmode($FH);
    my $xx = Digest::xxHash64->new;
    $xx->addfile($FH);
    close($FH);
    print $xx->hexdigest, '  ', $filename, "\n";

To calculate digest based on a small portion of a large file use the followings strategy:
(in this example, we calculate digest based on 64 bytes of the file starting at 123 byte postion.)
    use Digest::xxHash64;

    my $filename = __FILE__;
    open (my $FH, '<', $filename) or die "Can't open '$filename': $!";
    binmode($FH);
    seek($FH,0,123)
    my $xx = Digest::xxHash64->new;
    $xx->addfile($FH, 64);
    close($FH);
    print $xx->hexdigest, '  ', $filename, "\n";

Calculating digest for two different string:

    use Digest::xxHash64;

    my $xx = Digest::xxHash64->new;

    $xx->add($string1);
    print $xx->hexdigest, ' for ', $tring1, "\n";

    $xx->reset;

    $xx->add($string2);
    print $xx->hexdigest, ' for ', $tring2, "\n";


xxHash algorithm accept a seed value to set initial state of digest calculation.
This makes possible to produce uniquely different digest in a predictive way.
So, new and reset method accepts an optional argument representing the seed value.
The argument must be between 0 and 2^64-1

In this example two different digests are calculated to the same string by providing different seed values.
Note: unspecified seed value means to use 0 as seed value.

    use Digest::xxHash64;

    my $seed1 = 12345;
    my $xx = Digest::xxHash64->new($seed1);

    $xx->add($string1);
    print $xx->hexdigest, ' for ', $tring1, "\n";

    my $seed1 = 986767364;
    $xx->reset($seed2);

    $xx->add($string1);
    print $xx->hexdigest, ' for ', $tring1, "\n";



=head1 COPYRIGHT

xxHash code is covered by the BSD license and written by Yann Collet

This wrapper library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2019 Bela Bodecs

=cut
