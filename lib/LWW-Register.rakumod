use CRDT;
use CRDT::Timestamp;

unit class LWW-Register does CRDT;

has CRDT::Timestamp $!timestamp;
has                 $!value;
has Lock::Async     $!lock .= new;

method TWEAK(|) {
    without $!timestamp {
        $!timestamp .= new: :instance-id($.instance-id)
    }
}

method !value is rw {
    $!value
}

method export {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    %(:$!value, :$!timestamp)
}

method !timestamp is rw {
    $!timestamp
}

method set($value) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    $!timestamp++;
    $!value = $value;
}

method get {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    $!value
}

method copy {
    my $obj        = ::?CLASS.new;
    $obj!value     = |$!value;
    $obj!timestamp = CRDT::Timestamp.new: :instance-id($obj.instance-id), :counter($!timestamp.counter);
    $obj
}

multi method merge(::?CLASS $b) {
    self.merge: $b.export
}

multi method merge(% (:$value!, :$timestamp!)) {
    await $!lock.lock;
    LEAVE $!lock.unlock;
    if $timestamp > $!timestamp {
        $!value = $value;
        my $l = $!timestamp.counter;
        my $r = $timestamp.counter;
        $!timestamp++ xx $r - $l if $r > $l;
    }
    self
}