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

done-testing;
