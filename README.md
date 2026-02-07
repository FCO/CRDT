[![Actions Status](https://github.com/FCO/CRDT/workflows/test/badge.svg)](https://github.com/FCO/CRDT/actions)

NAME
====

CRDT - Conflict-free Replicated Data Types for Raku

SYNOPSIS
========

```raku
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
```

DESCRIPTION
===========

This distribution provides a common role `CRDT` and several concrete Conflict-free Replicated Data Types (CRDTs) implemented in Raku. CRDTs allow concurrent, replicated updates that always converge without coordination. Each type implements an associative, commutative, and idempotent `merge` operation so independently evolving replicas can be combined deterministically.

The `CRDT` role
---------------

All CRDT classes `does CRDT` and expose these common behaviors:

  * `.instance-id` — unique replica identifier (UUID by default).

  * `.changed` — a `Supply` that emits `.export` data after every mutation.

  * `.merged` — a `Supply` that emits `.export` data after every merge.

  * `.export` — returns a serializable representation of the state.

  * `.merge($other)` — merges another replica or exported data, returning the receiver.

  * `.copy` — deep copy with a fresh `.instance-id`.

These streams are useful to propagate state changes over a transport (queues, sockets, etc.). Subscribing replicas can call `.merge` with received `.export` payloads and converge.

Implemented CRDTs
-----------------

### G-Counter Grow-only counter. Only increments are allowed. Merge takes the pointwise maximum of per-replica contributions; numeric value is the sum.

```raku
my G-Counter $a .= new;
$a++;           # sugar for .increment
$a += 3;        # add many at once
my $b = $a.copy; $b++;
my $c = $a.merge: $b;    # merges by max per replica
say +$c;                 # numeric value
```

### PN-Counter Positive/Negative counter, implemented as two G-Counters. Supports increments and decrements. Merge is the max of each side; value is positive minus negative.

```raku
my PN-Counter $p .= new;
$p += 10; $p -= 3;       # value == 7
my $q = $p.copy; $q--;
my $r = $p.merge: $q;    # convergent result
say +$r;                 # 6
```

### G-Set Grow-only set. Elements can be added, never removed. Associative access is supported via `AT-KEY` proxy.

```raku
my %gs is G-Set;
%gs<a> = True;           # add
say %gs<a>;              # True
# removal is disallowed and dies
# %gs.unset: "a";
```

### 2P-Set (P2-Set) Two-Phase Set with separate add/remove sets. Once removed, an element cannot be re-added. Associative access supports `True` to add and `False` to remove.

```raku
my %tw is P2-Set;
%tw<a> = True;           # add
%tw<a> = False;          # remove — permanent
say %tw<a>;              # False
```

### LWW-Element-Set Last-Writer-Wins Element Set. Each add/remove is timestamped per replica; the latest action for an element decides membership.

```raku
my %l is LWW-Element-Set;
%l<a> = True;            # add
%l<a> = False;           # remove wins if newer
say %l<a>;               # Bool
```

### OR-Set Observed-Remove Set. Adds create unique tags; removes mark observed tags. An element is present if there exists an add tag not matched by a remove tag.

```raku
my %or is OR-Set;
%or<a> = True;           # add creates tag
%or<a> = False;          # remove marks observed tags
say %or<a>;              # Bool based on tags difference
```

### LWW-Register Last-Writer-Wins register storing any scalar value. Each set advances a per-replica timestamp; merge selects the value with the latest timestamp.

```raku
my LWW-Register $reg .= new;
$reg.set: 42;
my $copy = $reg.copy; $copy.set: 13;
$reg.merge($copy);       # latest wins
say $reg.get;            # 13
```

Event Streams Every mutation emits on `.changed`; every successful merge emits on `.merged`. Subscribers receive the current `.export` payload.
-----------------------------------------------------------------------------------------------------------------------------------------------

```raku
my G-Counter $a .= new;
my $iid = $a.instance-id;
$a.changed.tap: -> $exp { say $exp{$iid} };
$a.increment;  # tap prints 1
```

SEE ALSO
========

[https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)

AUTHOR
======

Fernando Correa <fco@cpan.org>

COPYRIGHT AND LICENSE
=====================

Copyright 2020–2026 Fernando Correa

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

