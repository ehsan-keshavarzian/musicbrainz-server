package MusicBrainz::Server::Entity::URL;

use Moose;
use MooseX::Types::URI qw( Uri );
use MusicBrainz::Server::Filters;

extends 'MusicBrainz::Server::Entity::CoreEntity';
with 'MusicBrainz::Server::Entity::Role::Linkable';

has 'url' => (
    is => 'rw',
    isa => Uri,
    coerce => 1
);

has 'description' => (
    is => 'rw',
    isa => 'Str'
);

has 'reference_count' => (
    is => 'rw',
    isa => 'Int'
);

sub pretty_name { shift->url->host }

sub name { shift->url->as_string }

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
