use UUID;
unit role CRDT:ver<0.0.11>:auth<zef:FCO>;

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

CRDT - Conflict-free Replicated Data Type

=head1 SYNOPSIS

=begin code :lang<raku>

use G-Counter;
use PN-Counter;
use G-Set;
use P2-Set;
use LWW-Element-Set;
use OR-Set;
use LWW-Register;

=end code

=head1 DESCRIPTION

CRDT is L<https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type>

=head1 AUTHOR

Fernando Correa <fco@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Fernando Correa

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
