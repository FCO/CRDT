use CRDT;
unit class G-Set does CRDT does Associative;

class X::G-Set::Unset is Exception {
    method message { "A item cannot be unset on a G-Set" }
}

has             %!values is SetHash;
has Lock::Async $!lock .= new;

method !values is rw { %!values }

method set($item) {
    %!values.set: $item
}

method unset($) { X::G-Set::Unset.new.throw }

method AT-KEY($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values.AT-KEY: $item
}

method copy {
    my $obj = ::?CLASS.new;
    $obj!values = |%!values;
    $obj
}

method merge(::?CLASS $b) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values = |(%!values ∪ $b!values);
    self
}