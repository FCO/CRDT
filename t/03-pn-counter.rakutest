use Test;
use lib ".";
use lib "t";
use PN-Counter;
use CRDTTester;

my PN-Counter $a .= new;
my $iid = $a.instance-id;

test-supply $a.changed, *.<positive>{$iid}, 1, 0, "positive";
test-supply $a.changed, *.<negative>{$iid}, 0, 0, "negative";
test-supply $a.changed, *.<positive>{$iid}, 2, 1, "positive";
test-supply $a.changed, *.<negative>{$iid}, 0, 1, "negative";
test-supply $a.changed, *.<positive>{$iid}, 3, 2, "positive";
test-supply $a.changed, *.<negative>{$iid}, 0, 2, "negative";
test-supply $a.changed, *.<positive>{$iid}, 4, 3, "positive";
test-supply $a.changed, *.<negative>{$iid}, 0, 3, "negative";

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

#my $*TEST-DEBUG = True;
test-supply $a.changed, *.<positive>{$iid}, 4, 0, "positive";
test-supply $a.changed, *.<negative>{$iid}, 4, 0, "negative";
test-supply $a.changed, *.<positive>{$iid}, 4, 1, "positive";
test-supply $a.changed, *.<negative>{$iid}, 5, 1, "negative";
test-supply $a.changed, *.<positive>{$iid}, 4, 2, "positive";
test-supply $a.changed, *.<negative>{$iid}, 6, 2, "negative";
test-supply $a.changed, *.<positive>{$iid}, 4, 3, "positive";
test-supply $a.changed, *.<negative>{$iid}, 7, 3, "negative";

lives-ok { $a.decrement: 4 }, "Decrements";
is $a.value, 0, "... worked";
is +$a,      0, "... +again";

lives-ok { $a-- }, "Decrements--";
is $a.value, -1, "... works";
is +$a,      -1, "... +again";

is $a--, -1, "X--";
is +$a,  -2, "... ok";

is (--$a).Int, -3, "--X";
is +$a,  -3, "... ok";

test-supply $a.changed, *.<positive>{$iid}, 17, 0, "positive";
test-supply $a.changed, *.<negative>{$iid}, 7,  0, "negative";
test-supply $a.changed, *.<positive>{$iid}, 17, 1, "positive";
test-supply $a.changed, *.<negative>{$iid}, 10,  1, "negative";

$a += 13;
is +$a, 10, "+=";

$a -= 3;
is +$a, 7, "-=";

my $b = $a.copy;
isa-ok $b, PN-Counter;
is +$b, 7;
isnt $a, $b;
isnt +(++$b), +$a;

is +($a + 3), 10, "X + y";
is +($a - 3), 4, "X - y";
is +$a, 7, "... did not change";

test-copy $a;

test-merge $a, $b, -> $res, :$last-merge {
    is +$res, +$last-merge with $last-merge;
    isa-ok $res, PN-Counter;
    is +$res,       8, "Is it 8?";
    is +($res + 1), 9, "Plus one equals 9";

    my $copy = $res.copy;
    is +(++$copy), 9, "does it pre decr?";
    is $copy++,    9, "does it post decr?";
    is +$copy,    10, "... ?";

    is +(--$copy), 9, "does it pre decr?";
    is $copy--,    9, "does it post decr?";
    is +$copy,     8, "... ?";
}

#my $*TEST-DEBUG = True;
test-supply $a.merged, *.<positive>{$iid}, 17,  0, "positive iid";
test-supply $a.merged, *.<positive><b>,     1,  0, "positive b";
test-supply $a.merged, *.<negative>{$iid}, 10,  0, "negative iid";
test-supply $a.merged, *.<positive>{$iid}, 17,  1, "positive iid";
test-supply $a.merged, *.<positive><b>,     1,  1, "positive b";
test-supply $a.merged, *.<negative>{$iid}, 10,  1, "negative iid";
test-supply $a.merged, *.<negative><c>,     6,  1, "negative c";

$a.merge: %(:positive{ b => 1 }, :negative{});
is +$a, 8;
$a.merge: %(:positive{ b => 1 }, :negative{ c => 6 });
is +$a, 2;

done-testing;
