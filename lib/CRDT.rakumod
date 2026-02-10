use UUID;
unit role CRDT:ver<0.0.16>:auth<zef:FCO>;

has Str $.instance-id           = ~UUID.new;
has Supplier $!change-supplier .= new;
has Supply $.changed            = $!change-supplier.Supply;
has Supplier $!merge-supplier  .= new;
has Supply $.merged             = $!merge-supplier.Supply;

method !emit-change { $!change-supplier.emit: self.export }
method !emit-merge  { $!merge-supplier.emit:  self.export }

method merge(::T CRDT:D: $ --> T) { ... }
method copy(::T CRDT:D: --> T)    { ... }
method export                     { ... }

method DESTROY {
    $!change-supplier.done;
    $!merge-supplier.done;
}

=begin pod

=head1 NAME

CRDT - Conflict-free Replicated Data Types for Raku

=head1 SYNOPSIS

=begin code :lang<raku>

use G-Counter;          # grow-only counter
use PN-Counter;         # positive/negative counter
use G-Set;              # grow-only set
use P2-Set;             # two-phase set (add/remove; remove is permanent)
use LWW-Element-Set;    # last-writer-wins element set
use OR-Set;             # observed-remove set
use LWW-Register;       # last-writer-wins register

# G-Counter
my G-Counter $gc .= new;
$gc.increment;           # +1
$gc += 3;                # +3 via operator
say +$gc;                # numeric value
my $gc2 = $gc.copy;      # independent replica (new instance-id)
my $gc-merged = $gc.merge($gc2);  # CRDT merge

# Subscribing to change/merge events
$gc.changed.tap: -> $export {    # emits $gc.export after each mutation
    say "changed: { $export{$gc.instance-id} }";
};
$gc.merged.tap: -> $export {     # emits $gc.export after each merge
    say "merged:  { $export{$gc.instance-id} }";
};

# PN-Counter
my PN-Counter $pn .= new;
$pn += 5;      # increment
$pn -= 2;      # decrement
say +$pn;      # current value

# G-Set
my %gs is G-Set;
%gs.set: "a";           # add
ok %gs<a>;
# associative access also works:
%gs<b> = True;           # add
# removal is not allowed on G-Set and throws:
# %gs.unset: "a";  # dies

# 2P-Set (P2-Set)
my %twophase is P2-Set;
%twophase<a> = True;     # add
%twophase<a> = False;    # remove (permanent)

# LWW-Element-Set
my %lww is LWW-Element-Set;
%lww<a> = True;          # add with timestamp
%lww<a> = False;         # remove wins if newer

# OR-Set
my %or is OR-Set;
%or<a> = True;           # add (creates a unique tag)
%or<a> = False;          # remove (observed tags)

# LWW-Register
my LWW-Register $reg .= new;
$reg.set: 42;
say $reg.get;            # 42
my $reg2 = $reg.copy;
my $reg-merged = $reg.merge($reg2);  # value chosen by latest timestamp

=end code

=head1 DESCRIPTION

This distribution provides a common role C<CRDT> and several concrete
Conflict-free Replicated Data Types (CRDTs) implemented in Raku.
CRDTs allow concurrent, replicated updates that always converge
without coordination. Each type implements an associative, commutative,
and idempotent C<merge> operation so independently evolving replicas
can be combined deterministically.

=head2 The C<CRDT> role

All CRDT classes C<does CRDT> and expose these common behaviors:

=item C<.instance-id> — unique replica identifier (UUID by default).
=item C<.changed> — a C<Supply> that emits C<.export> data after every mutation.
=item C<.merged>  — a C<Supply> that emits C<.export> data after every merge.
=item C<.export>  — returns a serializable representation of the state.
=item C<.merge($other)> — merges another replica or exported data, returning the receiver.
=item C<.copy>    — deep copy with a fresh C<.instance-id>.

These streams are useful to propagate state changes over a transport
(queues, sockets, etc.). Subscribing replicas can call C<.merge> with
received C<.export> payloads and converge.

=head2 Implemented CRDTs

=head3 G-Counter

Grow-only counter. Only increments are allowed. Merge takes the pointwise
maximum of per-replica contributions; numeric value is the sum.

=begin code :lang<raku>

my G-Counter $a .= new;
$a++;           # sugar for .increment
$a += 3;        # add many at once
my $b = $a.copy; $b++;
my $c = $a.merge: $b;    # merges by max per replica
say +$c;                 # numeric value

=end code

=head3 PN-Counter

Positive/Negative counter, implemented as two G-Counters. Supports increments
and decrements. Merge is the max of each side; value is positive minus negative.

=begin code :lang<raku>

my PN-Counter $p .= new;
$p += 10; $p -= 3;       # value == 7
my $q = $p.copy; $q--;
my $r = $p.merge: $q;    # convergent result
say +$r;                 # 6

=end code

=head3 G-Set

Grow-only set. Elements can be added, never removed. Associative access is
supported via C<AT-KEY> proxy.

=begin code :lang<raku>

my %gs is G-Set;
%gs<a> = True;           # add
say %gs<a>;              # True
# removal is disallowed and dies
# %gs.unset: "a";

=end code

=head3 2P-Set (P2-Set)

Two-Phase Set with separate add/remove sets. Once removed, an element cannot be
re-added. Associative access supports C<True> to add and C<False> to remove.

=begin code :lang<raku>

my %tw is P2-Set;
%tw<a> = True;           # add
%tw<a> = False;          # remove — permanent
say %tw<a>;              # False

=end code

=head3 LWW-Element-Set

Last-Writer-Wins Element Set. Each add/remove is timestamped per replica; the
latest action for an element decides membership.

=begin code :lang<raku>

my %l is LWW-Element-Set;
%l<a> = True;            # add
%l<a> = False;           # remove wins if newer
say %l<a>;               # Bool

=end code

=head3 OR-Set

Observed-Remove Set. Adds create unique tags; removes mark observed tags.
An element is present if there exists an add tag not matched by a remove tag.

=begin code :lang<raku>

my %or is OR-Set;
%or<a> = True;           # add creates tag
%or<a> = False;          # remove marks observed tags
say %or<a>;              # Bool based on tags difference

=end code

=head3 LWW-Register

Last-Writer-Wins register storing any scalar value. Each set advances a
per-replica timestamp; merge selects the value with the latest timestamp.

=begin code :lang<raku>

my LWW-Register $reg .= new;
$reg.set: 42;
my $copy = $reg.copy; $copy.set: 13;
$reg.merge($copy);       # latest wins
say $reg.get;            # 13

=end code

=head3 CRDT::Storage

A container for multiple CRDT instances keyed by unique IDs. Each item stores
its CRDT and a content hash based on the CRDT's C<.export>. The storage
computes a global hash over items to quickly detect identical replicas.
It supports adding items, querying, copying, and C<.sync($other)> to converge
with another storage by merging per-item CRDTs.

=begin code :lang<raku>

use CRDT::Storage;
use G-Counter;

my CRDT::Storage $store .= new;

# add a counter and mutate it
my $id = $store.add-item: G-Counter.new;
$store.get-item($id).increment;

# replicate and diverge, then converge via sync
my $replica = $store.copy;
$replica.get-item($id) += 2;

$store.sync($replica);       # merges underlying CRDTs by id
say +$store.get-item($id);   # 3

# item introspection
say $store.has-item($id);        # True
say $store.get-item-hash($id);   # sha1 of JSON export

=end code

=head2 Event Streams

Every mutation emits on C<.changed>; every successful merge emits on C<.merged>.
Subscribers receive the current C<.export> payload.

=begin code :lang<raku>

my G-Counter $a .= new;
my $iid = $a.instance-id;
$a.changed.tap: -> $exp { say $exp{$iid} };
$a.increment;  # tap prints 1

=end code

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type>

=head1 AUTHOR

Fernando Correa <fco@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2020–2026 Fernando Correa

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
