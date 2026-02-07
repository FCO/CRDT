use Test;
use lib ".";
use lib "t";
use CRDTTester;
use LWW-Element-Set;
use CRDT::Timestamp;

my %a is LWW-Element-Set;

test-supply %a.changed, *.<add>.keys>>.value.sort, < a   >, 0;
test-supply %a.changed, *.<del>.keys>>.value.sort, <     >, 0;
test-supply %a.changed, *.<add>.keys>>.value.sort, < a b >, 1;
test-supply %a.changed, *.<del>.keys>>.value.sort, <     >, 1;
test-supply %a.changed, *.<add>.keys>>.value.sort, < a b >, 2;
test-supply %a.changed, *.<del>.keys>>.value.sort, < b   >, 2;

%a.set: "a";

ok %a<a>;
nok %a<b>;

%a.set: "b";
ok %a<a>;
ok %a<b>;

%a.unset: "b";
ok %a<a>;
nok %a<b>;

my $b = %a.copy;
$b.set: "c";

ok $b<c>;
nok %a<c>;

$b.unset: "d";
nok $b<d>;
$b.set: "d";
ok $b<d>;
$b.unset: "d";
nok $b<d>;
$b.set: "d";
ok $b<d>;
$b.unset: "d";
nok $b<d>;

is %a.elems, 1;
is %a.keys.sort, < a >;

test-copy %a;

test-merge %a, $b, -> $res, :$last-merge {
    is $res<a>, $last-merge<a> with $last-merge;
    is $res<b>, $last-merge<b> with $last-merge;
    is $res<c>, $last-merge<c> with $last-merge;
    is $res<d>, $last-merge<d> with $last-merge;
    ok $res<a>;
    nok $res<b>;
    ok $res<c>;
    nok $res<d>;
    $res.set: "d";
    ok $res<d>;
    $res.unset: "d";
    nok $res<d>;
    $res.set: "d";
    ok $res<d>;
    $res.unset: "d";
    nok $res<d>;
}

#my $*TEST-DEBUG = True;
test-supply %a.merged, *.<add>.keys>>.value.sort, < 1 a b >, 0;
test-supply %a.merged, *.<del>.keys>>.value.sort, < b     >, 0;

my LWW-Element-Set::Item $item .= new: :1value, :timestamp(CRDT::Timestamp.new: :instance-id<b>);

%a.merge: %( :add(set(($item))), :del(set()), :timestamp(CRDT::Timestamp.new: :instance-id<b>) );

my %n is LWW-Element-Set;
%n<a> = True;

ok %n<a>;
nok %n<b>;

%n<b> = True;
ok %n<a>;
ok %n<b>;

%n<b> = False;
ok %n<a>;
nok %n<b>;

my $m = %n.copy;
$m<c> = True;

ok $m<c>;
nok %n<c>;

$m<d> = False;
nok $m<d>;
$m<d> = True;
ok $m<d>;
$m<d> = False;
nok $m<d>;
$m<d> = True;
ok $m<d>;
$m<d> = False;
nok $m<d>;

is %n.elems, 1;
is %n.keys.sort, < a >;

done-testing;
