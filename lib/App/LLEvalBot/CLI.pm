package App::LLEvalBot::CLI;
use strict;
use warnings;
use utf8;

use Getopt::Long 2.39;
use Pod::Usage qw/pod2usage/;

use App::LLEvalBot;

sub run {
    my ($class, @argv) = @_;

    my ($opt, $rest_argv) = $class->parse_options(@argv);
    my $bot = App::LLEvalBot->new(config => $opt);
    $bot->run;
}

sub parse_options {
    my ($class, @argv) = @_;

    my $parser = Getopt::Long::Parser->new(
        config => [qw/posix_default no_ignore_case pass_through/],
    );

    $parser->getoptionsfromarray(\@argv, \my %opt, qw/
        host=s
        port=s
        password=s
        channels=s@
        nickname=s
        enable_ssl
    /) or pod2usage(1);

    my @required_options = qw/host channels/;
    pod2usage(2) if grep {!exists $opt{$_}} @required_options;

    $opt{channels}      = [ map { split /,/, $_ } @{ $opt{channels} } ];
    $opt{join_channels} = delete $opt{channels};
    $opt{nickname}      //= 'lleval_bot';

    (\%opt, \@argv);
}

1;

__END__

=encoding utf-8

=head1 NAME

App::LLEvalBot::CLI - IRC bot for LLeval

=head1 SYNOPSIS

    % lleval-bot.pl --channels=test --host=irc.example.com [opt]

=head1 DESCRIPTION

App::LLEvalBot is IRC bot for LLeval.
