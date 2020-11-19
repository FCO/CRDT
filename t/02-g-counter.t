use Test;
use lib ".";
use lib "t";
use G-Counter;
use CRDTTester;

my G-Counter $a .= new;

is $a.value, 0, "Starts with 0";
is +$a,      0, "... +again";

lives-ok { $a.increment }, "Increments";
is $a.value, 1, "... worked";
is +$a,      1, "... +again";

lives-ok { $a++ }, "Increments++";
is $a.value, 2, "... works";
is +$a,      2, "... +again";

is $a++, 2, "X++";
is +$a,  3, "... ok";

is (++$a).Int, 4, "++X";
is +$a,  4, "... ok";

$a += 3;
is +$a, 7, "+=";

my $b = $a.copy;
isa-ok $b, G-Counter;
is +$b, 7;
isnt $a, $b;
isnt +(++$b), +$a;

is +($a + 3), 10, "X + y";
is +$a, 7, "... did not change";

test-copy $a;

test-merge $a, $b, -> $res {
    isa-ok $res, G-Counter;
    is +$res,       8, "Is it 8?";
    is +($res + 1), 9, "Plus one equals 9";

    my $copy = $res.copy;
    is +(++$copy), 9, "does it pre incr?";
    is $copy++,    9, "does it post incr?";
    is +$copy,    10, "... ?";
}

dies-ok { $a-- };
dies-ok { --$a };

done-testing;
