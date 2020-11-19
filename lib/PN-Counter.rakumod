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

method increment {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!positive{ $.instance-id }++;
    self
}

method decrement {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!negative{ $.instance-id }++;
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

method merge(::?CLASS $b) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!positive = |do for (%!positive.keys ∪ $b!positive).keys -> $key {
        $key => %!positive{$key} max $b!positive{$key}
    }.BagHash;
    %!negative = |do for (%!negative.keys ∪ $b!negative).keys -> $key {
        $key => %!negative{$key} max $b!negative{$key}
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
    $a.increment for ^$b
}

multi infix:<-=>(::?CLASS $a, UInt() $b) is export {
    $a.decrement for ^$b
}

multi infix:<+>(::?CLASS $a, ::?CLASS $b) is export { $a.copy.merge: $b }

multi infix:<+>(::?CLASS $a, UInt $b) is export {
    my ::?CLASS $c = $a.copy;
    $c.increment for ^$b;
    $c
}

multi infix:<+>(::?CLASS $a, ::?CLASS $b) is export { $a.copy.merge: $b.invert }

multi infix:<+>(::?CLASS $a, UInt $b) is export {
    my ::?CLASS $c = $a.copy;
    $c.decrement for ^$b;
    $c
}