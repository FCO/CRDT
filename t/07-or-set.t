use Test;
use lib ".";
use lib "t";
use CRDTTester;
use OR-Set;

my %a is OR-Set;

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

nok $b<d>;
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

test-supply %a.merged, *.<add>.keys>>.value.sort, < 1 a b >, 0;
test-supply %a.merged, *.<del>.keys>>.value.sort, < b     >, 0;

my OR-Set::Item $item .= new: :1value;

%a.merge: %( :add(set(($item))), :del(set()) );

done-testing;
