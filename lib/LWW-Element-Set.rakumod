use CRDT;
#| Implements 2P-Set
unit class LWW-Element-Set does CRDT does Associative;

class Item {
    has      $.value     is required;
    has UInt $.timestamp is required;

    method WHICH { $!value.WHICH }
}

has UInt        $!timestamp;
has             %!add is SetHash;
has             %!del is SetHash;
has Lock::Async $!lock .= new;

method !add is rw {
    %!add
}

method !del is rw {
    %!del
}

method !timestamp is rw {
    $!timestamp
}

method set($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!add.set: Item.new: :value($item), :timestamp($!timestamp++);
}

method unset($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!del.set: Item.new: :value($item), :timestamp($!timestamp++);
}

method AT-KEY($item) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    my $add = %!add.keys.first: *.value eqv $item;
    my $del = %!del.keys.first: *.value eqv $item;
    do if $add && $del {
        if $add.timestamp > $del.timestamp {
            True
        } else {
            False
        }
    } elsif $add {
        True
    } else {
        False
    }
}

method copy {
    my $obj        = ::?CLASS.new;
    $obj!add       = |%!add;
    $obj!del       = |%!del;
    $obj!timestamp = $!timestamp;
    $obj
}

method merge(::?CLASS $b) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %!add       = |(%!add ∪ $b!add);
    %!del       = |(%!del ∪ $b!del);
    $!timestamp = $!timestamp max $b!timestamp;
    self
}