use CRDT;
#| Implements 2P-Set
unit class P2-Set does CRDT does Associative;

has             %!add is SetHash;
has             %!del is SetHash;
has Lock::Async $!lock .= new;

method !add is rw {
    %!add
}

method !del is rw {
    %!del
}

method export {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %(:%!add, :%!del)
}

method set($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!add.set: $item
}

method unset($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!del.set: $item #if %!add{$item}
}

method AT-KEY($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    !%!del.AT-KEY($item) && %!add.AT-KEY: $item
}

method copy {
    my $obj = ::?CLASS.new;
    $obj!add = |%!add;
    $obj!del = |%!del;
    $obj
}

multi method merge(::?CLASS $b) {
    self.merge: $b.export
}

multi method merge(% (:$add!, :$del!)) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!add = |(%!add ∪ $add);
    %!del = |(%!del ∪ $del);
    self
}