use CRDT;
unit class PN-Counter does CRDT;

has             %!positive is BagHash;
has             %!negative is BagHash;
has Lock::Async $!lock .= new;

method !positive is rw {
    %!positive
}

method !negative is rw {
    %!negative
}

method export {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %(:%!positive, :%!negative)
}

multi method increment {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    %!positive{ $.instance-id }++;
    self
}

multi method increment(UInt() $b) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    %!positive{ $.instance-id } += $b;
    self
}


multi method decrement {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    %!negative{ $.instance-id }++;
    self
}

multi method decrement(UInt() $b) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    %!negative{ $.instance-id } += $b;
    self
}

method value {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!positive.values.sum - %!negative.values.sum
}

method compare(::?CLASS $b) {
    self.value <=> $b.value
}

multi method merge(::?CLASS $b) {
    self.merge: $b.export
}

multi method merge(% (:$positive!, :$negative!)) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-merge;
    }
    %!positive = |do for (%!positive.keys ∪ $positive).keys -> $key {
        $key => %!positive{$key} max $positive{$key}
    }.BagHash;
    %!negative = |do for (%!negative.keys ∪ $negative).keys -> $key {
        $key => %!negative{$key} max $negative{$key}
    }.BagHash;
    self
}

method Int     { $.value }
method Numeric { $.Int }
method succ    { $.increment }
method prev    { $.decrement }

method copy {
    my $obj = ::?CLASS.new;
    $obj!positive = |%!positive;
    $obj!negative = |%!negative;
    $obj
}

method invert {
    my $obj = ::?CLASS.new;
    $obj!positive = |%!negative;
    $obj!negative = |%!positive;
    $obj
}

multi prefix:<++>(::?CLASS $a) is export {
    $a.increment
}

multi postfix:<++>(::?CLASS $a) is export {
    my Int $val = +$a;
    $a.increment;
    $val
}

multi prefix:<-->(::?CLASS $a) is export {
    $a.decrement
}

multi postfix:<-->(::?CLASS $a) is export {
    my Int $val = +$a;
    $a.decrement;
    $val
}

multi infix:<+=>(::?CLASS $a, UInt() $b) is export {
    $a.increment: $b
}

multi infix:<-=>(::?CLASS $a, UInt() $b) is export {
    $a.decrement: $b
}

multi infix:<+>(::?CLASS $a, ::?CLASS $b) is export { $a.copy.merge: $b }

multi infix:<+>(::?CLASS $a, UInt $b) is export {
    my ::?CLASS $c = $a.copy;
    $c.increment: $b;
    $c
}

multi infix:<->(::?CLASS $a, ::?CLASS $b) is export { $a.copy.merge: $b.invert }

multi infix:<->(::?CLASS $a, UInt $b) is export {
    my ::?CLASS $c = $a.copy;
    $c.decrement: $b;
    $c
}
