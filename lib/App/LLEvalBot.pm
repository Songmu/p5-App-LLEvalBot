package App::LLEvalBot;
use 5.010001;
use strict;
use warnings;

our $VERSION = "0.01";

use UnazuSan;
use LLEval;
use Config::Pit;

use Mouse;

has config_name => (
    is      => 'ro',
    isa     => 'HashRef',
    default => 'lleval_bot',
);

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub {
        my $self = shift;
        pit_get($self->config_name => {
            host     => '',
            port     => '',
            password => '',
            channel  => '',
            nickname => '',
        });
    },
);

has unazu_config => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has lleval => (
    is      => 'ro',
    isa     => 'LLEval',
    lazy    => 1,
    default => sub { LLEval->new },
);

has unazu_san => (
    is      => 'ro',
    isa     => 'UnazuSan',
    lazy    => 1,
    default => sub {
        my $self = shift;

        UnazuSan->new(
            %{ $self->config },
            %{ $self->unazu_config },
        );
    },
);

has _languages => (
    is    => 'ro',
    isa   => 'HashRef',
    lazy  => 1,
    default => sub {
        shift->lleval->languages;
    },

);

no Mouse;

sub call_eval {
    my ($self, $message) = @_;

    my $lleval = $self->lleval;

    my %languages = %{ $self->_languages };
    my $langs     = '(?:' . join('|', map { quotemeta } keys %languages) . ')';

    my $reg_nick = quotemeta $self->config->{nickname};
    $message =~ s/\A \s* $reg_nick \s* : \s*//xms;

    my ($lang, $src) = $message =~ /\A ($langs) \s+ (.+)/xms;
    unless ($lang) {
        $lang = 'pl516';
        $src = $message;
    }
    if ($lang =~ /^pl/) {
        unless ( $src =~ /(?:print|say)/ ) {
            $src = "print sub { ${src} }->()";
        }
        $src = 'use 5.14.2;use warnings;'.$src if $lang eq 'pl';
        $src = 'use 5.16.1;use warnings;'.$src if $lang eq 'pl516';
    }

    my $result = $lleval->call_eval( $src, $lang );
    $result->{lang} = $lang;
    $result;
}

sub run {
    my $self = shift;

    my $unazu_san = $self->unazu_san;
    $unazu_san->on_command(
        '' => sub {
            my $receive = shift;

            my $result   = $self->call_eval($receive->message);
            my $language = $self->_languages->{$result->{lang}};

            # error?
            if ($result->{status}) {
                $receive->reply("$language returned $result->{status}!!");
            }
            if ($result->{error}) {
                $receive->reply("error: $result->{error}");
            }

            for my $out (qw/stdout stderr/) {
                my $s = $result->{$out};
                next unless defined $s;
                my @lines = split /\n/, $s;
                if (@lines > 15) {
                    @lines = @lines[0..14];
                    push @lines, ' (snip!)';
                }
                $receive->reply($_) for @lines;
            }
        },
    );
    $unazu_san->run;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::LLEvalBot - It's new $module

=head1 SYNOPSIS

    use App::LLEvalBot;

=head1 DESCRIPTION

App::LLEvalBot is ...

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

