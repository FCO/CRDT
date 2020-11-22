unit class CRDT::Timestamp;

class X::CRDT::Timestamp::Previous {
    method message { "Timestamp cannot go back in time" }
}

has UInt $.counter = 0;
has Str  $.instance-id is required;

method succ {
    ::?CLASS.new: :$!instance-id, :counter($!counter + 1)
}

method prev {
    X::CRDT::Timestamp::Previous.new.throw
}

multi infix:<< < >>(::?CLASS $a, ::?CLASS $b) is export {
    $a cmp $b == -1
}

multi infix:<< > >>(::?CLASS $a, ::?CLASS $b) is export {
    $a cmp $b == 1
}

multi infix:<< == >>(::?CLASS $a, ::?CLASS $b) is export {
    $a cmp $b == 0
}

multi infix:<< <= >>(::?CLASS $a, ::?CLASS $b) is export {
    $a < $b || $a == $b
}

multi infix:<< >= >>(::?CLASS $a, ::?CLASS $b) is export {
    $a > $b || $a == $b
}

multi infix:<cmp>(::?CLASS $a, ::?CLASS $b) is export {
    ($a.counter, $a.instance-id) cmp ($b.counter, $b.instance-id)
}

multi infix:<max>(::?CLASS $a, ::?CLASS $b) is export {
    max $a, $b, :by{ .counter, .instance-id }
}