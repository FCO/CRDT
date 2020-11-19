use Test;
use CRDT;
sub test-copy(CRDT $a is copy) is export is test-assertion {
    subtest {
        my $b = $a;
        my $c;
        for ^10 {
            $c = $b.copy;
            $b = $a.copy;
            isnt $a.instance-id, $b.instance-id;
            isnt $b.instance-id, $c.instance-id;
            isnt $a.instance-id, $c.instance-id;
            $b = $c;
        }
    }, "Test copy"
}
sub test-merge(CRDT $a-o is copy, CRDT $b-o is copy, &test) is export is test-assertion {
    $a-o .= copy;
    $b-o .= copy;
    subtest {
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test $a.merge: $b;
                test $a
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test $b.merge: $a;
                test $b
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test $a.merge($b).merge: $a;
                test $a
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test $b.merge($a).merge: $b;
                test $b
            }
        }
    }, "Test merge"
}