use CRDT;
unit class G-Counter does CRDT;

class X::G-Counter::Decrease is Exception {
    method message { "cannot decrease the value of a G-Counter" }
}

has             %!values is BagHash;
has Lock::Async $!lock .= new;

method !values is rw { %!values }

method export {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values
}

method increment {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values{ $.instance-id }++;
    self
}

method value {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values.values.sum
}

method compare(::?CLASS $b) {
    self.value <=> $b.value
}

multi method merge(::?CLASS $b) {
    self.merge: $b.export
}

multi method merge($data) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values = |do for (%!values.keys ∪ $data).keys -> $key {
        $key => %!values{$key} max $data{$key}
    }.BagHash;
    self
}

method Int     { $.value }
method Numeric { $.Int }
method succ    { $.increment }

method copy {
    my $obj = ::?CLASS.new;
    $obj!values = |%!values;
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

multi prefix:<-->(::?CLASS)  is export { X::G-Counter::Decrease.new.throw }
multi postfix:<-->(::?CLASS) is export { X::G-Counter::Decrease.new.throw }

multi infix:<+=>(::?CLASS $a, UInt() $b) is export {
    $a.increment for ^$b
}

multi infix:<+>(::?CLASS $a, ::?CLASS $b) is export { $a.copy.merge: $b }

multi infix:<+>(::?CLASS $a, UInt $b) is export {
    my ::?CLASS $c = $a.copy;
    $c.increment for ^$b;
    $c
}