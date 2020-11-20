use CRDT;
unit class G-Set does CRDT does Associative;

class X::G-Set::Unset is Exception {
    method message { "A item cannot be unset on a G-Set" }
}

has             %!values is SetHash;
has Lock::Async $!lock .= new;

method !values is rw { %!values }

method export {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values
}

method set($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
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


multi method merge(::?CLASS $b) {
    self.merge: $b.export;
}

multi method merge($data) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!values = |(%!values ∪ $data);
    self
}