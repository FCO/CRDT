use Test;
use lib ".";
use lib "t";
use CRDTTester;
use LWW-Register;

my LWW-Register $a .= new;

$a.set: 42;
is $a.get, 42;

$a.set: 13;
is $a.get, 13;

my $b = $a.copy;
isa-ok $b, LWW-Register;
is $b.get, 13;
is $b.get, $a.get;

test-copy $a;

test-merge $a, $b, -> $res, :$last-merge {
    is $res.get, $last-merge.get with $last-merge;
    ok $res.get == ($a|$b).get;
}

done-testing;
