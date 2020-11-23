use CRDT;
use CRDT::Timestamp;
#| Implements 2P-Set
unit class LWW-Element-Set does CRDT does Associative;

class Item {
    has                 $.value     is required;
    has CRDT::Timestamp $.timestamp is required;

    method WHICH { $!value.WHICH }
}

has CRDT::Timestamp $!timestamp;
has                 %!add is SetHash;
has                 %!del is SetHash;
has Lock::Async     $!lock .= new;

method TWEAK(|) {
    without $!timestamp {
        $!timestamp .= new: :instance-id($.instance-id)
    }
}

method !add is rw {
    %!add
}

method !del is rw {
    %!del
}

method export {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %(:%!add, :%!del, :$!timestamp)
}

method !timestamp is rw {
    $!timestamp
}

method set($item) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    %!add.set: Item.new: :value($item), :timestamp($!timestamp++);
    $item
}

method unset($item) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    %!del.set: Item.new: :value($item), :timestamp($!timestamp++);
    $item
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
    $obj!timestamp = CRDT::Timestamp.new: :instance-id($obj.instance-id), :counter($!timestamp.counter);
    $obj
}

multi method merge(::?CLASS $b) {
    self.merge: $b.export
}

multi method merge(% (:$add!, :$del!, :$timestamp!)) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-merge;
    }
    %!add       = |(%!add ∪ $add);
    %!del       = |(%!del ∪ $del);
    my $l = $!timestamp.counter;
    my $r = $timestamp.counter;
    $!timestamp++ xx $r - $l if $r > $l;
    self
}