package Time::Format::Compiler;

use 5.008004;
use strict;
use warnings;
use Carp;
use Time::Local qw//;
use POSIX qw//;

our $VERSION = "0.01";

use constant {
    SEC => 0,
    MIN => 1,
    HOUR => 2,
    DAY => 3,
    MONTH => 4,
    YEAR => 5,
    WDAY => 6,
    YDAY => 7,
    ISDST => 8
};

our %formats = (
    'rfc2822' => '%a, %d %b %Y %T %z',
    'rfc822' => '%a, %d %b %y %T %z',
);

# copy from POSIX/strftime/GNU/PP.pm
my @offset2zone = qw(
    -11       0 SST     -11       0 SST
    -10       0 HAST    -09       1 HADT
    -10       0 HST     -10       0 HST
    -09:30    0 MART    -09:30    0 MART
    -09       0 AKST    -08       1 AKDT
    -09       0 GAMT    -09       0 GAMT
    -08       0 PST     -07       1 PDT
    -08       0 PST     -08       0 PST
    -07       0 MST     -06       1 MDT
    -07       0 MST     -07       0 MST
    -06       0 CST     -05       1 CDT
    -06       0 GALT    -06       0 GALT
    -05       0 ECT     -05       0 ECT
    -05       0 EST     -04       1 EDT
    -05       1 EASST   -06       0 EAST
    -04:30    0 VET     -04:30    0 VET
    -04       0 AMT     -04       0 AMT
    -04       0 AST     -03       1 ADT
    -03:30    0 NST     -02:30    1 NDT
    -03       0 ART     -03       0 ART
    -03       0 PMST    -02       1 PMDT
    -03       1 AMST    -04       0 AMT
    -03       1 WARST   -03       1 WARST
    -02       0 FNT     -02       0 FNT
    -02       1 UYST    -03       0 UYT
    -01       0 AZOT    +00       1 AZOST
    -01       0 CVT     -01       0 CVT
    +00       0 GMT     +00       0 GMT
    +00       0 WET     +01       1 WEST
    +01       0 CET     +02       1 CEST
    +01       0 WAT     +01       0 WAT
    +02       0 EET     +02       0 EET
    +02       0 IST     +03       1 IDT
    +02       1 WAST    +01       0 WAT
    +03       0 FET     +03       0 FET
    +03:07:04 0 zzz     +03:07:04 0 zzz
    +03:30    0 IRST    +04:30    1 IRDT
    +04       0 AZT     +05       1 AZST
    +04       0 GST     +04       0 GST
    +04:30    0 AFT     +04:30    0 AFT
    +05       0 DAVT    +07       0 DAVT
    +05       0 MVT     +05       0 MVT
    +05:30    0 IST     +05:30    0 IST
    +05:45    0 NPT     +05:45    0 NPT
    +06       0 BDT     +06       0 BDT
    +06:30    0 CCT     +06:30    0 CCT
    +07       0 ICT     +07       0 ICT
    +08       0 HKT     +08       0 HKT
    +08:45    0 CWST    +08:45    0 CWST
    +09       0 JST     +09       0 JST
    +09:30    0 CST     +09:30    0 CST
    +10       0 PGT     +10       0 PGT
    +10:30    1 CST     +09:30    0 CST
    +11       0 CAST    +08       0 WST
    +11       0 NCT     +11       0 NCT
    +11       1 EST     +10       0 EST
    +11       1 LHST    +10:30    0 LHST
    +11:30    0 NFT     +11:30    0 NFT
    +12       0 FJT     +12       0 FJT
    +13       0 TKT     +13       0 TKT
    +13       1 NZDT    +12       0 NZST
    +13:45    1 CHADT   +12:45    0 CHAST
    +14       0 LINT    +14       0 LINT
    +14       1 WSDT    +13       0 WST
);

sub tzoffset {
    my ($colons, @t) = @_;

    # Normalize @t array, we need seconds without frac
    $t[0] = int $t[0];

    my $diff = (exists $ENV{TZ} and $ENV{TZ} eq 'GMT')
             ? 0
             : Time::Local::timegm(@t) - Time::Local::timelocal(@t);
    my $h = $diff / 60 / 60;
    my $m = $diff / 60 % 60;
    my $s = $diff % 60;

    my $fmt = do {
        if ($colons == 0) {
            '%+03d%02u';
        }
        elsif ($colons == 1) {
            '%+03d:%02u';
        }
        elsif ($colons == 2) {
            '%+03d:%02u:%02u';
        }
        elsif ($colons == 3) {
            $s ? '%+03d:%02u:%02u' : $m ? '%+03d:%02u' : '%+03d';
        }
        else {
            '%%' . ':' x $colons . 'z';
        };
    };

    return sprintf $fmt, $h, $m, $s;
}

sub tzname {
    my @t = @_;

    return 'GMT' if exists $ENV{TZ} and $ENV{TZ} eq 'GMT';

    my $diff = tzoffset(3, @t);

    my @t1 = my @t2 = @t;
    @t1[3,4] = (1, 1);  # winter
    @t2[3,4] = (1, 7);  # summer

    my $diff1 = tzoffset(3, @t1);
    my $diff2 = tzoffset(3, @t2);

    for (my $i=0; $i < @offset2zone; $i += 6) {
        next unless $offset2zone[$i] eq $diff1 and $offset2zone[$i+3] eq $diff2;
        return $diff2 eq $diff ? $offset2zone[$i+5] : $offset2zone[$i+2];
    }

    if ($diff =~ /^([+-])(\d\d)$/) {
        return sprintf 'GMT%s%d', $1 eq '-' ? '+' : '-', $2;
    };

    return 'Etc';
}

our %rules = (
    '%' => [q!%s!, q!%!],
    'a' => [q!%s!, q!$weekday_abbr[$_[WDAY]-1]!],
    'A' => [q!%s!, q!$weekday_name[$_[WDAY]-1]!],
    'b' => [q!%s!, q!$month_abbr[$_[MONTH]]!],
    'B' => [q!%s!, q!$month_name[$_[MONTH]]!],
    'c' => [q!%s %s % 2d %02d:%02d:%02d %04d!, q!$weekday_abbr[$_[WDAY]-1], $month_abbr[$_[MONTH]], $_[DAY], $_[HOUR], $_[MIN], $_[SEC], $_[YEAR]+1900!],
    'C' => [q!%d!, q!$_[YEAR]%100!],
    'd' => [q!%02d!, q!$_[DAY]!],
    'D' => [q!%02d/%02d/%02d!, q!$_[MONTH]+1,$_[DAY],$_[YEAR]%100!],
    'e' => [q!%d!, q!$_[DAY]!],
    'F' => [q!%04d-%02d-%02d!, q!$_[YEAR]+1900,$_[MONTH]+1,$_[DAY]!],
    'G' => [q!%s!], #posix
    'g' => [q!%s!], #posix
    'h' => [q!%s!, q!$month_abbr[$_[MONTH]]!],
    'H' => [q!%02d!, q!$_[HOUR]!],
    'I' => [q!%02d!, q!$_[HOUR]%12 || 1!],
    'j' => [q!%03d!, q!$_[YDAY]+1!],
    'k' => [q!% 2d!, q!$_[HOUR]!],
    'l' => [q!% 2d!, q!$_[HOUR]%12 || 1!],
    'm' => [q!%02d!, q!$_[MONTH]+1!],
    'M' => [q!%02d!, q!$_[MIN]!],
    'n' => [q!%s!, q!"\n"!],
    'p' => [q!%s!, q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM"!],
    'P' => [q!%s!, q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "am" : "pm"!],
    'r' => [q!%02d:%02d:%02d %s!, q!$_[HOUR]%12 || 1, $_[MIN], $_[SEC]!],
    'R' => [q!%02d:%02d!, q!$_[HOUR], $_[MIN]!],
    's' => [q!%s!, q!Time::Local::timegm(@_)!],
    'S' => [q!%02d!, q!$_[SEC]!],
    't' => [q!%s!, q!"\t"!],
    'T' => [q!%02d:%02d:%02d!, q!$_[HOUR], $_[MIN], $_[SEC]!],
    'U' => [q!%s!], #posix
    'u' => [q!%d!, q!$_[WDAY] || 7!],
    'v' => [q!%s!], #posix
    'W' => [q!%s!], #posix
    'w' => [q!%d!, q!$_[WDAY]!],
    'x' => [q!%02d/%02d/%02d!, q!$_[MONTH]+1,$_[DAY],$_[YEAR]%100!],
    'X' => [q!%02d:%02d:%02d!, q!$_[HOUR], $_[MIN], $_[SEC]!],
    'y' => [q!%02d!, q!$_[YEAR]%100!],
    'Y' => [q!%02d!, q!$_[YEAR]+1900!],
    'z' => [q!%s!, q!$this->{tzoffset}!],
    'Z' => [q!%s!, q!$this->{tzname}!],
    '%' => [q!%s!, q!'%'!],
    '+' => [q!%s!], #posix
);

my $char_handler = sub {
    my ($self, $char) = @_;
    die unless exists $rules{$char};
    my ($format, $code) = @{$rules{$char}};
    if ( !$code ) {
        $code = q~POSIX::strftime('%~.$format.q~',@_)~;
    }
    push @{$self->{_args}}, $code;
    return $format;
};

sub new {
    my $class = shift;
    my $fmt = shift || "rfc2822";
    $fmt = $formats{$fmt} if exists $formats{$fmt};

    my $self = bless {
        fmt => $fmt,
    }, $class; 
    $self->compile();
    return $self;
}

sub compile {
    my $self = shift;
    my $fmt = $self->{fmt};
    $self->{_require_posix} = 0;
    $self->{_args} = [];
    my $rule_chars = join "", keys %rules;
    $fmt =~ s!\%E([cCxXyY])!%$1!g;
    $fmt =~ s!\%O([deHImMSuUVwWy])!%$1!g;
    $fmt =~ s!
        (?:
             \%([$rule_chars])
        )
    ! $char_handler->($self, $1) !egx;
    my $args = delete $self->{_args};
    my $require_posix = delete $self->{_require_posix};
    my @weekday_name = qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @weekday_abbr = qw( Sun Mon Tue Wed Thu Fri Sat );
    my @month_name = qw( January February March April May June July August September October November December );
    my @month_abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

    $fmt = q~sub {
        my $this = shift;
        if ( ! exists $this->{tzoffset} || ! exists $this->{isdst_cache} || $_[ISDST] ne $this->{isdst_cache} ) {
            $this->{isdst_cache} = $_[ISDST];
            $this->{tzoffset} = tzoffset(0, @_);
            $this->{tzname} = tzname(@_);
        }
        sprintf q!~ . $fmt .  q~!,~ . join(",\n", @$args) . q~;
    }~;
    $self->{_code} = $fmt;
    $self->{_handler} = eval $fmt; ## no critic    
    die $@ if $@;
}



sub display {
    my $self = shift;
    Carp::croak 'Usage: display(sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)'
        if @_ != 9;
    $self->{_handler}->($self,@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Time::Format::Compiler - It's new $module

=head1 SYNOPSIS

    use Time::Format::Compiler;

=head1 DESCRIPTION

Time::Format::Compiler is ...

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

