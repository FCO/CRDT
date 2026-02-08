unit class CRDT::Storage;
use JSON::Fast <!pretty sorted-keys enums-as-value>;
use String::Utils <sha1>;
use CRDT;
use UUID;

my class Item {
    has Str  $.id = ~UUID.new;
    has CRDT $.data is rw;
    has Str  $.hash = sha1 to-json $!data.export;

    method calc-hash {
        $!hash = sha1 to-json $!data.export;
    }

    method copy {
        ::?CLASS.new: :$!id, :data($!data.copy)
    }

    multi method merge(Item $item) {
        $!data.merge: $item.data
    }
}

has Item %.items;
has Str  $.hash = self.calc-hash;

method calc-hash {
    $!hash = sha1 %!items.kv.map(-> $key, Item $item { $key => $item.calc-hash }).Hash.&to-json
}

multi method add-item(CRDT $data, Str :$id) {
    $.add-item: Item.new: :$data, |(:$id with $id);
}

multi method add-item(Item $item) {
    %!items{ $item.id } = $item;
    $item.id
}

method has-item(Str $id) { %!items{$id}:exists }

method get-raw-item(Str $id) { %!items{$id} }

method get-item(Str $id) { $.get-raw-item($id).data }

method get-item-hash(Str $id) { $.get-raw-item($id).hash }

multi method update($id, Item $b) {
    $.get-raw-item($id).merge: $b;
}

method sync(::?CLASS $b) {
    return self if $.calc-hash eq $b.calc-hash;
    my %ids is Set = %!items.keys ∪ $b.items.keys;
    for %ids.keys -> $id {
        next unless $b.has-item: $id;
        unless $.has-item: $id {
            $.add-item: $b.get-raw-item: $id
        }
        next if $.get-item-hash($id) eq $b.get-item-hash($id);
        $.update: $id, $b.get-raw-item: $id
    }
    self
}

method copy {
    ::?CLASS.new: :items( |%!items.kv.map(-> $key, $item { $key => $item.copy }).Hash )
}
