use Test;
use lib ".";
use lib "t";
use CRDTTester;
use G-Set;

my %a is G-Set;

test-supply %a.changed, *.keys.sort, < a       >, 0;
test-supply %a.changed, *.keys.sort, < a b     >, 1;
test-supply %a.changed, *.keys.sort, < a b d   >, 2;

%a.set: "a";

ok %a<a>;
nok %a<b>;

%a.set: "b";
ok %a<a>;
ok %a<b>;

my $b = %a.copy;
$b.set: "c";

ok $b<c>;
nok %a<c>;

%a.set: "d";

is %a.elems, 3;
is %a.keys.sort, <a b d>;

test-copy %a;

test-merge %a, $b, -> $res, :$last-merge {
    is $res<a>, $last-merge<a> with $last-merge;
    is $res<b>, $last-merge<b> with $last-merge;
    is $res<c>, $last-merge<c> with $last-merge;
    is $res<d>, $last-merge<d> with $last-merge;
    is $res<e>, $last-merge<e> with $last-merge;
    is $res<f>, $last-merge<f> with $last-merge;
    ok $res<a>;
    ok $res<b>;
    ok $res<c>;
    ok $res<d>;
    nok $res<e>;
    nok $res<f>;
}

test-supply %a.merged, *.keys.sort, < 1 2 3 a b d >, 0;
test-supply %a.merged, *.keys.sort, < 1 2 3 a b d >, 1;
test-supply %a.merged, *.keys.sort, < 1 2 3 A B a b d >, 2;

%a.merge: set <1 2 3>;
%a.merge: set <1 2 3 a b d>;
%a.merge: set < A B >;

done-testing;
