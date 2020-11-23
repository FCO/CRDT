use Test;
use lib ".";
use lib "t";
use CRDTTester;
use P2-Set;

my %a is P2-Set;

test-supply %a.changed, *.<add>.keys.sort, < a   >, 0;
test-supply %a.changed, *.<del>.keys.sort, <     >, 0;
test-supply %a.changed, *.<add>.keys.sort, < a b >, 1;
test-supply %a.changed, *.<del>.keys.sort, <     >, 1;
test-supply %a.changed, *.<add>.keys.sort, < a b >, 2;
test-supply %a.changed, *.<del>.keys.sort, < b   >, 2;

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

test-copy %a;

test-merge %a, $b, -> $res, :$last-merge {
    is $res<a>, $last-merge<a> with $last-merge;
    is $res<b>, $last-merge<b> with $last-merge;
    is $res<c>, $last-merge<c> with $last-merge;
    is $res<d>, $last-merge<d> with $last-merge;
    is $res<e>, $last-merge<e> with $last-merge;
    is $res<f>, $last-merge<f> with $last-merge;
    ok $res<a>;
    nok $res<b>;
    ok $res<c>;
    nok $res<d>;
    nok $res<e>;
    nok $res<f>;
}

test-supply %a.changed, *.<add>.keys.sort, < A a b >, 0;
test-supply %a.changed, *.<del>.keys.sort, < b     >, 0;
test-supply %a.changed, *.<add>.keys.sort, < A a b >, 1;
test-supply %a.changed, *.<del>.keys.sort, < 1 b   >, 1;

%a.merge: %(:add(set < A >), :del(set <   >));
%a.merge: %(:add(set <   >), :del(set < 1 >));

done-testing;
