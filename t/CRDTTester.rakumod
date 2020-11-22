use Test;
use CRDT;
sub test-copy(CRDT $a is copy) is export #`(is test-assertion) {
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
sub test-merge(CRDT $a-o is copy, CRDT $b-o is copy, &test) is export #`(is test-assertion) {
    my $a-x = $a-o.export;
    my $b-x = $b-o.export;
    $a-o .= copy;
    $b-o .= copy;
    my $last-merge;
    subtest {
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $a.merge: $b;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $a
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $b.merge: $a;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $b
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $a.merge($b).merge: $a;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $a
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-o.copy;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $b.merge($a).merge: $b;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $b
            }
        }
    }, "Test merge";

    subtest {
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-x;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $a.merge: $b;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $a
            }
        }
        subtest {
            for ^10 {
                my $a = $a-x;
                my $b = $b-o.copy;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $b.merge: $a;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $b
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-x;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $a.merge($b).merge: $a;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $a
            }
        }
        subtest {
            for ^10 {
                my $a = $a-x;
                my $b = $b-o.copy;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $b.merge($a).merge: $b;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $b
            }
        }
        subtest {
            for ^10 {
                my $a = $a-o.copy;
                my $b = $b-x;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $a.merge($b).merge: $a-x;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $a
            }
        }
        subtest {
            for ^10 {
                my $a = $a-x;
                my $b = $b-o.copy;

                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $last-merge = $b.merge($a).merge: $b-x;
                test |(:$last-merge if $last-merge && &test.signature.params.first: *.name eq '$last-name'), $b
            }
        }
    }, "Test merge exported data"
}