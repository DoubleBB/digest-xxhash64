use utf8;
use strict;
use warnings;
use Test::More;
use Math::Int64;
use Digest::xxH64  1.03 qw( xxHash64 xxHash64hex xxHash64bin xx64 xx64hex xx64bin xxH64 xxH64hex xxH64bin);

# testing functional interface
is xxHash64hex("abc"), '44BC2CF5AD770999', 'Check hexa digest output';
is xxHash64hex("abc", 0), '44BC2CF5AD770999', 'Check hexa digest output';

is xx64hex("abc"), '44BC2CF5AD770999', 'Check hexa digest output';
is xx64hex("abc", 0), '44BC2CF5AD770999', 'Check hexa digest output';

is uc(unpack('H*',xx64bin("abc"))), '44BC2CF5AD770999', 'Check hexa digest output';
is uc(unpack('H*',xx64bin("abc", 0))), '44BC2CF5AD770999', 'Check hexa digest output';


is xxHash64("abc"), Math::Int64::hex_to_uint64("0x44BC2CF5AD770999"), 'Check nativ digest output';
is xxHash64("abc", 0), Math::Int64::hex_to_uint64("0x44BC2CF5AD770999"), 'Check nativ digest output';

is xx64("abc"), Math::Int64::hex_to_uint64("0x44BC2CF5AD770999"), 'Check nativ digest output';
is xx64("abc", 0), Math::Int64::hex_to_uint64("0x44BC2CF5AD770999"), 'Check nativ digest output';

is uc(unpack('H*',xxHash64bin("abc"))), '44BC2CF5AD770999', 'Check hexa digest output';
is uc(unpack('H*',xxHash64bin("abc", 0))), '44BC2CF5AD770999', 'Check hexa digest output';


# testing OO interface
my $xx = new_ok( 'Digest::xxH64' );

is $xx->add("abc"), 3, 'Short string data adding - 3 characters';
is $xx->hexdigest(), '44BC2CF5AD770999', 'Check hexa digest output';

is $xx->reset(), 0, "Reset internal state";
is $xx->add('0' x 1000), 1000, 'Long string data (0) adding - 1000 characters';
is $xx->add('A' x 1000), 1000, 'Long string data (A) adding - 1000 characters';
is $xx->hexdigest(), 'B3121836846A6563', 'Check hexa digest output';

is $xx->reset(), 0, "Reset internal state";
is $xx->add("abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"), 62, 'Full english alphabet adding';
is $xx->hexdigest(), "D5000C4AC53D14A0", 'Check hexa digest output';

is $xx->reset(), 0, "Reset internal state";
is $xx->add("abc"), 3, "Short string of 3 characters added";
my $xx2 = $xx->clone();
isa_ok $xx2, 'Digest::xxH64';

is $xx->add("defghijklmnopqrstuvwxyz0123456789"), 33, "Longer string added";
is $xx->hexdigest(), "64F23ECF1609B766", 'Check hexa digest output';


is $xx2->add("defghijklmnopqrstuvwxyz"), 23, '2nd data adding (a)';
is $xx2->add("0123456789"), 10, '2nd data adding (b)';
is $xx2->add("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), 26, '2nd data adding (c)';
is $xx2->hexdigest(), "D5000C4AC53D14A0", 'Check hexa digest output';

is $xx->reset(0), 0, "Reset internal state";
is $xx->add("abcdefghijklmnopqrstuvwxyz0123456789"), 36, "Lower case english alphabet added";
is $xx->hexdigest(), "64F23ECF1609B766", 'Check hexa digest output';
is $xx->digest(), Math::Int64::hex_to_uint64("0x64F23ECF1609B766"), 'Check 64 bit unsigned int digest output';

my $FH;
ok open($FH, '<', __FILE__), "Opening this test file";
ok binmode($FH), 'Switch to binary read mode';
ok 0<$xx->addfile($FH), "Reading whole file";
is length($xx->hexdigest()), 16, "Check hexa digest size";

is $xx->reset(), 0, "Reset internal state state";
seek($FH,0,0);

is $xx->addfile($FH, 100), 100, "Reading some data from the begining of this test file";
close($FH);
is length($xx->hexdigest()), 16, "Check hexa digest size";

done_testing;
