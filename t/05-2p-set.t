use Test;
use lib ".";
use lib "t";
use CRDTTester;
use P2-Set;

my %a is P2-Set;

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

test-merge %a, $b, -> $res {
    ok $res<a>;
    nok $res<b>;
    ok $res<c>;
    nok $res<d>;
    nok $res<e>;
    nok $res<f>;
}

done-testing;
