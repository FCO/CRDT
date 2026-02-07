use CRDT;
use UUID;
unit class OR-Set does CRDT does Associative;

class Item {
    has $.value is required;
    has %.tags  is SetHash;

    method WHICH { $!value.WHICH }
    method add-tag {
        %!tags.set: ~UUID.new
    }
    method union-tags(%tags) {
        %!tags = |(%!tags ∪ %tags)
    }
}

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

method set($value) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    unless %!add{$value} {
        %!add.set: Item.new: :$value
    }
    my $add = %!add.keys.first: *.value eqv $value;
    $add.add-tag;
    $value
}

method unset($value) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-change;
    }
    unless %!del{$value} {
        %!del.set: Item.new: :$value
    }
    my $add = %!add.keys.first: *.value eqv $value;
    my $del = %!del.keys.first: *.value eqv $value;
    $del.union-tags: $add.?tags // set();
    $value
}

method AT-KEY($item) is rw {
    Proxy.new:
        FETCH => sub ($) {
            await $!lock.lock;
            LEAVE $!lock.unlock;
            my $add = %!add.keys.first: *.value eqv $item;
            my $del = %!del.keys.first: *.value eqv $item;
            do if ($add.?tags // set()) && ($del.?tags // set()) {
                so ($add.tags (-) $del.tags).elems
            } else {
                so $add
            }
        },
        STORE => sub ($, Bool() $value) {
            $value ?? self.set: $item !! self.unset: $item
        }
}

method keys {
    %!add.keys>>.value.grep: { self.AT-KEY($_) }
}

method elems { self.keys.elems }

method copy {
    my $obj        = ::?CLASS.new;
    $obj!add       = |%!add;
    $obj!del       = |%!del;
    $obj
}

multi method merge(::?CLASS $b) {
    self.merge: $b.export
}

multi method merge(% (:$add!, :$del!)) {
    await $!lock.lock;
    LEAVE {
        $!lock.unlock;
        self!emit-merge;
    }
    %!add       = |(%!add ∪ $add);
    %!del       = |(%!del ∪ $del);
    self
}
