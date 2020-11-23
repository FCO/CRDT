use Test;
use lib ".";
use lib "t";
use CRDTTester;
use LWW-Register;
use CRDT::Timestamp;

my LWW-Register $a .= new;

test-supply $a.changed, *.<value>, 42, 0;
test-supply $a.changed, *.<value>, 13, 1;

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

test-supply $a.merged, *.<value>, 3.14, 0;
test-supply $a.merged, *.<value>, "bla", 1;

$a.merge: %( :value(3.14), :timestamp(CRDT::Timestamp.new: :5counter, :instance-id<a>) );
$a.merge: %( :value<bla>, :timestamp(CRDT::Timestamp.new: :6counter, :instance-id<a>) );

done-testing;
