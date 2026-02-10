use CRDT;
use CRDT::Timestamp;
#| Implements 2P-Hash
unit class LWW-Hash does CRDT does Associative;

class Item {
    has Str             $.key       is required;
    has CRDT::Timestamp $.timestamp is required;
    has                 $.value;

    method WHICH { $!key.WHICH }
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

method export {
    $!lock.protect: {
        %(:%!add, :%!del, :$!timestamp)
    }
}

method set($key, $value) {
    LEAVE self!emit-change;
    $!lock.protect: {
        %!add.set: Item.new: :$key, :timestamp($!timestamp++), :$value;
    }
    $value
}

method unset($key) {
    LEAVE self!emit-change;

    my $value = self.AT-KEY: $key;
    $!lock.protect: {
        %!del.set: Item.new: :$key, :timestamp($!timestamp++);
    }
    $value
}

method DELETE-KEY($key) {
    self.unset: $key
}

method AT-KEY($key) is rw {
    Proxy.new:
        FETCH => sub ($) {
            $!lock.protect: {
                my $add = %!add.keys.first: *.key eqv $key;
                my $del = %!del.keys.first: *.key eqv $key;
                do if $add && $del {
                    $add.timestamp > $del.timestamp
                    ?? $add.value
                    !! Nil
                } else {
                    $add.?value
                }
            }
        },
        STORE => sub ($, $value) {
            self.set: $key, $value
        }
}

method keys {
    %!add.keys>>.key.grep: { self.AT-KEY: $_ }
}

method values {
    @.keys.map({ self.AT-KEY: $_ }).grep: *.defined
}

method kv {
    $.keys.map: { |( $_, self.AT-KEY: $_ ) }
}

method elems { self.keys.elems }

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

method !add       is rw { %!add }
method !del       is rw { %!del }
method !timestamp is rw { $!timestamp }

multi method merge(% (:%add!, :%del!, :$timestamp!)) {
    LEAVE self!emit-merge;
    $!lock.protect: {
        %!add ∪= %add;
        %!del ∪= %del;
        my $l = $!timestamp.counter;
        my $r = $timestamp.counter;
        $!timestamp++ xx $r - $l if $r > $l;
    }
    self
}
