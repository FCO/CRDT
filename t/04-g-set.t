use Test;
use lib ".";
use lib "t";
use CRDTTester;
use G-Set;

my %a is G-Set;

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

test-copy %a;

test-merge %a, $b, -> $res {
    ok $res<a>;
    ok $res<b>;
    ok $res<c>;
    ok $res<d>;
    nok $res<e>;
    nok $res<f>;
}

done-testing;
