use UUID;
unit role CRDT:ver<0.0.1>:auth<cpan:FCO>;

has Str $.instance-id = ~UUID.new;
method merge(::T CRDT:D: T --> T) { ... }
method copy(::T CRDT:D: --> T)    { ... }

=begin pod

=head1 NAME

CRDT - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use CRDT;

=end code

=head1 DESCRIPTION

CRDT is ...

=head1 AUTHOR

Fernando Correa <fernando.correa@humanstate.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Fernando Correa

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
