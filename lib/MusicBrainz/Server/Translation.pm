package MusicBrainz::Server::Translation;
use MooseX::Singleton;

use Encode;
use I18N::LangTags ();
use I18N::LangTags::Detect;
use DBDefs;

use Locale::Messages qw( bindtextdomain dgettext dpgettext dngettext );
use Cwd qw (abs_path);

use Sub::Exporter -setup => {
    exports => [qw( l lp ln )],
    groups => {
        default => [qw( l lp ln )]
    }
};

has 'languages' => (
    isa => 'ArrayRef',
    is => 'rw',
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
        all_system_languages => 'elements',
    }
);

has 'bound' => (
    isa => 'Bool',
    is => 'rw',
    default => 0
);

sub _bind_domain
{
    my ($self, $domain) = @_;
    # copied from Locale::TextDomain
    my @search_dirs = map $_ . '/LocaleData', @INC;
    my $found_dir = '';
         
    TRYDIR: foreach my $dir (map { abs_path $_ } grep { -d $_ } @search_dirs) {
        local *DIR;
        if (opendir DIR, $dir) {
            my @files = map { "$dir/$_/LC_MESSAGES/$domain.mo" } 
                grep { ! /^\.\.?$/ } readdir DIR;

            foreach my $file (@files) {
                if (-f $file || -l $file) {
                    # If we find a non-readable file on our way,
                    # we access has been disabled on purpose.
                    # Therefore no -r check here.
                    $found_dir = $dir;
                    last TRYDIR;
                }
            }
        }
    }
     
    bindtextdomain $domain => $found_dir;
    $self->{bound} = 1;
}

sub build_languages_from_header
{
    my ($self, $headers) = @_;
    $self->languages([
        I18N::LangTags::implicate_supers(
            I18N::LangTags::Detect->http_accept_langs(
                $headers->header('Accept-Language')
            )
        ),
        'i-default'
    ]);
}

sub _set_language
{
    my $self = shift;
    # return if $ENV{LANGUAGE};

    my @avail_lang = grep {
        my $l = $_;
        grep { $l eq $_ } DBDefs::MB_LANGUAGES
    } $self->all_system_languages;

    $ENV{LANGUAGE} = $avail_lang[0] if @avail_lang;
}

sub gettext
{
    my ($self, $msgid, $vars) = @_;

    my %vars = %$vars if (ref $vars eq "HASH");

    $self->_bind_domain('mb_server') unless $self->bound;
    $self->_set_language;

    $msgid =~ s/\r*\n\s*/ /xmsg if defined($msgid);

    return $self->_expand(dgettext('mb_server' => $msgid), %vars) if $msgid;
}

sub pgettext
{
    my ($self, $msgid, $msgctxt, $vars) = @_;

    my %vars = %$vars if (ref $vars eq "HASH");

    $self->_bind_domain('mb_server') unless $self->bound;
    $self->_set_language;

    $msgid =~ s/\r*\n\s*/ /xmsg if defined($msgid);

    return $self->_expand(dpgettext('mb_server' => $msgctxt, $msgid), %vars) if $msgid;
}

sub ngettext {
    my ($self, $msgid, $msgid_plural, $n, $vars) = @_;

    my %vars = %$vars if (ref $vars eq "HASH");

    $self->_bind_domain('mb_server') unless $self->bound;
    $self->_set_language;

    $msgid =~ s/\r*\n\s*/ /xmsg;

    return $self->_expand(dngettext('mb_server' => $msgid, $msgid_plural, $n), %vars);
}

sub _expand
{
    my ($self, $string, %args) = @_;

    $string = decode('utf-8', $string);

    my $re = join '|', map { quotemeta $_ } keys %args;

    $string =~ s/\{($re)\|(.*?)\}/defined $args{$1} ? "<a href=\"" . $args{$1} . "\">" . (defined $args{$2} ? $args{$2} : $2) . "<\/a>" : "{$0}"/ge;
    $string =~ s/\{($re)\}/defined $args{$1} ? $args{$1} : "{$1}"/ge;

    return $string;
}

sub l  { __PACKAGE__->instance->gettext(@_) }
sub lp { __PACKAGE__->instance->pgettext(@_) }
sub ln { __PACKAGE__->instance->ngettext(@_) }

1;
