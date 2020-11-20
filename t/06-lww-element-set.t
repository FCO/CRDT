use Test;
use lib ".";
use lib "t";
use CRDTTester;
use LWW-Element-Set;

my %a is LWW-Element-Set;

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

test-copy %a;

test-merge %a, $b, -> $res {
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

done-testing;