package MusicBrainz::Server::Controller::Role::Delete;
use MooseX::Role::Parameterized -metaclass => 'MusicBrainz::Server::Controller::Role::Meta::Parameterizable';

parameter 'edit_type' => (
    isa => 'Int',
    required => 1
);

parameter 'edit_arguments' => (
    isa => 'CodeRef',
    default => sub { sub { } }
);

role {
    my $params = shift;
    my %extra = @_;

    $extra{consumer}->name->config(
        action => {
            delete => { Chained => 'load', RequireAuth => undef }
        }
    );

    method 'delete' => sub {
        my ($self, $c) = @_;
        my $entity_name = $self->{entity_name};
        my $edit_entity = $c->stash->{ $entity_name };
        if ($c->model($self->{model})->can_delete($edit_entity->id)) {
            $c->stash( can_delete => 1 );
            $self->edit_action($c,
                form        => 'Confirm',
                type        => $params->edit_type,
                item        => $edit_entity,
                edit_args   => { $params->edit_arguments->($edit_entity) },
                on_creation => sub {
                    my $edit = shift;
                    my $url = $edit->is_open
                        ? $c->uri_for_action($self->action_for('show'), [ $edit_entity->gid ])
                        : $c->uri_for_action('/search');
                    $c->response->redirect($url);
                },
            );
        }
    };
};

1;
