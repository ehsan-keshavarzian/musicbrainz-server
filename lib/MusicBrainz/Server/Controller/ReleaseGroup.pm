package MusicBrainz::Server::Controller::ReleaseGroup;
use Moose;
BEGIN { extends 'MusicBrainz::Server::Controller'; }

use MusicBrainz::Server::Constants qw(
    $EDIT_RELEASEGROUP_DELETE
    $EDIT_RELEASEGROUP_EDIT
    $EDIT_RELEASEGROUP_MERGE
    $EDIT_RELEASEGROUP_CREATE
);
use MusicBrainz::Server::Form::Confirm;

with 'MusicBrainz::Server::Controller::Role::Annotation';
with 'MusicBrainz::Server::Controller::Role::Details';
with 'MusicBrainz::Server::Controller::Role::Relationship';
with 'MusicBrainz::Server::Controller::Role::Rating';
with 'MusicBrainz::Server::Controller::Role::Tag';
with 'MusicBrainz::Server::Controller::Role::EditListing';

use aliased 'MusicBrainz::Server::Entity::ArtistCredit';

__PACKAGE__->config(
    model       => 'ReleaseGroup',
    entity_name => 'rg',
    namespace   => 'release_group',
);

sub base : Chained('/') PathPart('release-group') CaptureArgs(0) { }

after 'load' => sub
{
    my ($self, $c) = @_;

    my $rg = $c->stash->{rg};
    $c->model('ReleaseGroup')->load_meta($rg);
    if ($c->user_exists) {
        $c->model('ReleaseGroup')->rating->load_user_ratings($c->user->id, $rg);
    }
    $c->model('ReleaseGroupType')->load($rg);
    $c->model('ArtistCredit')->load($rg);
};

sub show : Chained('load') PathPart('')
{
    my ($self, $c) = @_;

    my $releases = $self->_load_paged($c, sub {
        $c->model('Release')->find_by_release_group($c->stash->{rg}->id, shift, shift);
    });

    $c->model('Medium')->load_for_releases(@$releases);
    $c->model('MediumFormat')->load(map { $_->all_mediums } @$releases);
    $c->model('Country')->load(@$releases);
    $c->model('ReleaseLabel')->load(@$releases);
    $c->model('Label')->load(map { $_->all_labels } @$releases);

    $c->stash(
        template => 'release_group/index.tt',
        releases => $releases
    );
}

with 'MusicBrainz::Server::Controller::Role::Delete' => {
    edit_type      => $EDIT_RELEASEGROUP_DELETE,
    edit_arguments => sub { release_group => shift }
};

with 'MusicBrainz::Server::Controller::Role::Create' => {
    path           => '/release-group/create',
    form           => 'Recording',
    edit_type      => $EDIT_RELEASEGROUP_CREATE,
    gid_from_edit  => sub { shift->release_group->gid },
    edit_arguments => sub {
        my ($self, $c) = @_;
        my $artist_gid = $c->req->query_params->{artist};
        if ( my $artist = $c->model('Artist')->get_by_gid($artist_gid) ) {
            my $rg = MusicBrainz::Server::Entity::ReleaseGroup->new(
                artist_credit => ArtistCredit->from_artist($artist)
            );
            return ( item => $rg );
        }
    }
};

with 'MusicBrainz::Server::Controller::Role::Edit' => {
    form           => 'ReleaseGroup',
    edit_type      => $EDIT_RELEASEGROUP_EDIT,
    edit_arguments => sub { release_group => shift }
};

with 'MusicBrainz::Server::Controller::Role::Merge' => {
    edit_type => $EDIT_RELEASEGROUP_MERGE,
    confirmation_template => 'release_group/merge_confirm.tt',
    search_template       => 'release_group/merge_search.tt',
    edit_arguments => sub {
        return (
            old_release_group_id => shift->id,
            new_release_group_id => shift->id,
        );
    }
};

1;

=head1 NAME

MusicBrainz::Server::Controller::ReleaseGroup - controller for release groups

=head1 COPYRIGHT

Copyright (C) 2009 Oliver Charles

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
