package POSIX::strftime::Compiler;

use 5.008004;
use strict;
use warnings;
use Carp;
use Time::Local qw//;

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
    ISDST => 8,
    ISO_WEEK_START_WDAY => 1,  # Monday
    ISO_WEEK1_WDAY      => 4,  # Thursday
    YDAY_MINIMUM        => -366,
    FMT => 0,
    ARGS => 1,
    TZOFFSET => 2,
    TZNAME => 3,
    ISDST_CACHE => 4,
    CODE => 6,
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

sub iso_week_days {
    my ($yday, $wday) = @_;

    # Add enough to the first operand of % to make it nonnegative.
    my $big_enough_multiple_of_7 = (int(- YDAY_MINIMUM / 7) + 2) * 7;
    return ($yday
        - ($yday - $wday + ISO_WEEK1_WDAY + $big_enough_multiple_of_7) % 7
        + ISO_WEEK1_WDAY - ISO_WEEK_START_WDAY);
}

sub isleap {
    my $year = shift;
    return ($year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0)) ? 1 : 0
}

sub isodaysnum {
    my @t = @_;

    # Normalize @t array, we need WDAY
    $t[SEC] = int $t[SEC];

    my $year = ($t[YEAR] + ($t[YEAR] < 0 ? 1900 % 400 : 1900 % 400 - 400));
    my $year_adjust = 0;
    my $days = iso_week_days($t[YDAY], $t[WDAY]);

    if ($days < 0) {
        # This ISO week belongs to the previous year.
        $year_adjust = -1;
        $days = iso_week_days($t[YDAY] + (365 + isleap($year -1)), $t[WDAY]);
    }
    else {
        my $d = iso_week_days($t[YDAY] - (365 + isleap($year)), $t[WDAY]);
        if ($d >= 0) {
            # This ISO week belongs to the next year.  */
            $year_adjust = 1;
            $days = $d;
        }
    }

    return ($days, $year_adjust);
}

sub isoyearnum {
    my ($days, $year_adjust) = isodaysnum(@_);
    return $_[YEAR] + 1900 + $year_adjust;
}

sub isoweeknum {
    my ($days, $year_adjust) = isodaysnum(@_);
    return int($days / 7) + 1;
}

sub first_day_wday {
    my $year = shift;
    (gmtime( Time::Local::timegm((0,0,0,1,0,$year)) ))[WDAY];
}

our %rules = (
    '%' => [q!%s!, q!%!],
    'a' => [q!%s!, q!$weekday_abbr[$_[WDAY]]!],
    'A' => [q!%s!, q!$weekday_name[$_[WDAY]]!],
    'b' => [q!%s!, q!$month_abbr[$_[MONTH]]!],
    'B' => [q!%s!, q!$month_name[$_[MONTH]]!],
    'c' => [q!%s %s %2d %02d:%02d:%02d %04d!, q!$weekday_abbr[$_[WDAY]], $month_abbr[$_[MONTH]], $_[DAY], $_[HOUR], $_[MIN], $_[SEC], $_[YEAR]+1900!],
    'C' => [q!%02d!, q!($_[YEAR]+1900)/100!],
    'd' => [q!%02d!, q!$_[DAY]!],
    'D' => [q!%02d/%02d/%02d!, q!$_[MONTH]+1,$_[DAY],$_[YEAR]%100!],
    'e' => [q!%2d!, q!$_[DAY]!],
    'F' => [q!%04d-%02d-%02d!, q!$_[YEAR]+1900,$_[MONTH]+1,$_[DAY]!],
    'G' => [q!%04d!, q!isoyearnum(@_)!],
    'g' => [q!%02d!, q!isoyearnum(@_)%100!],
    'h' => [q!%s!, q!$month_abbr[$_[MONTH]]!],
    'H' => [q!%02d!, q!$_[HOUR]!],
    'I' => [q!%02d!, q!$_[HOUR]%12 || 1!],
    'j' => [q!%03d!, q!$_[YDAY]+1!],
    'k' => [q!%2d!, q!$_[HOUR]!],
    'l' => [q!%2d!, q!$_[HOUR]%12 || 1!],
    'm' => [q!%02d!, q!$_[MONTH]+1!],
    'M' => [q!%02d!, q!$_[MIN]!],
    'n' => [q!%s!, q!"\n"!],
    'N' => [q!%s!, q!substr(sprintf('%.9f', $_[SEC] - int $_[SEC]), 2)!],
    'p' => [q!%s!, q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM"!],
    'P' => [q!%s!, q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "am" : "pm"!],
    'r' => [q!%02d:%02d:%02d %s!, q!$_[HOUR]%12 || 1, $_[MIN], $_[SEC], $_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM"!],
    'R' => [q!%02d:%02d!, q!$_[HOUR], $_[MIN]!],
    's' => [q!%s!, q!int(Time::Local::timegm(@_))!],
    'S' => [q!%02d!, q!$_[SEC]!],
    't' => [q!%s!, q!"\t"!],
    'T' => [q!%02d:%02d:%02d!, q!$_[HOUR], $_[MIN], $_[SEC]!],
    'u' => [q!%d!, q!$_[WDAY] || 7!],
    'U' => [q!%02d!, q!int( ($_[YDAY] + 1 - (7 - first_day_wday($_[YEAR])) + 6 ) / 7 )!], #first Sunday as the first day of week 01
    'V' => [q!%02d!, q!isoweeknum(@_)!],
    'w' => [q!%d!, q!$_[WDAY]!],
    'W' => [q!%02d!, q!int( ($_[YDAY] + 1 - (7 - first_day_wday($_[YEAR])) + 5) / 7 )!], #first Monday as the first day of week 01
    'x' => [q!%02d/%02d/%02d!, q!$_[MONTH]+1,$_[DAY],$_[YEAR]%100!],
    'X' => [q!%02d:%02d:%02d!, q!$_[HOUR], $_[MIN], $_[SEC]!],
    'y' => [q!%02d!, q!$_[YEAR]%100!],
    'Y' => [q!%02d!, q!$_[YEAR]+1900!],
    'z' => [q!%s!, q!$this->[TZOFFSET]!],
    'Z' => [q!%s!, q!$this->[TZNAME]!],
    '%' => [q!%s!, q!'%'!],
);

my $char_handler = sub {
    my ($self, $char) = @_;
    die unless exists $rules{$char};
    my ($format, $code) = @{$rules{$char}};
    push @{$self->[ARGS]}, $code;
    return $format;
};

sub new {
    my $class = shift;
    my $fmt = shift || "rfc2822";
    $fmt = $formats{$fmt} if exists $formats{$fmt};

    my $self = bless [$fmt], $class;
    $self->compile();
    return $self;
}


sub compile {
    my $self = shift;
    my $fmt = $self->[FMT];
    $self->[ARGS] = [];
    my $rule_chars = join "", keys %rules;
    $fmt =~ s!\%E([cCxXyY])!%$1!g;
    $fmt =~ s!\%O([deHImMSuUVwWy])!%$1!g;
    $fmt =~ s!
        (?:
             \%([$rule_chars])
        )
    ! $char_handler->($self, $1) !egx;
    my $args = $self->[ARGS];
    my @weekday_name = qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @weekday_abbr = qw( Sun Mon Tue Wed Thu Fri Sat );
    my @month_name = qw( January February March April May June July August September October November December );
    my @month_abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    $fmt = q~sub ($@) {
        my $this = shift;
        if ( @_ != 9  && @_ != 6 ) {
            Carp::croak 'Usage: to_string(sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)';
        }
        if ( @_ == 6 ) {
            @_ = gmtime(Time::Local::timegm(@_));
        }
        if ( ! defined $this->[TZOFFSET] || ! defined $this->[ISDST_CACHE] || $_[ISDST] ne $this->[ISDST_CACHE] ) {
            $this->[ISDST_CACHE] = $_[ISDST];
            $this->[TZOFFSET] = tzoffset(0, @_);
            $this->[TZNAME] = tzname(@_);
        }
        sprintf(q!~ . $fmt .  q~!,~ . join(",", @$args) . q~);
    }~;
    $self->[CODE] = $fmt;
    my $handler = eval $fmt; ## no critic    
    die $@ if $@;
    {
        no warnings 'redefine';
        *to_string = $handler;
    }
}


1;
__END__

=encoding utf-8

=head1 NAME

POSIX::strftime::Compiler - Compile strftime to perl. for logger and servers

=head1 SYNOPSIS

    use POSIX::strftime::Compiler;

    my $psc = POSIX::strftime::Compiler->new('%a, %d %b %Y %T %z');
    say $psc->to_string(localtime):

=head1 DESCRIPTION

POSIX::strftime::Compiler compiles strftime's format to perl. And generates formatted string.
Because this module compiles strftime to perl code, it has good performance.

POSIX::strftime::Compiler has compatibility with GNU's strftime, but only supports "C" locale.
It's useful for loggers and servers. 

=head1 METHODS

=over 4

=item new($fmt:String)

create instance of POSIX::strftime::Compiler.

=item to_string(@time)

generate formatted string.

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  $psc->to_string($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst):

=back

=head1 SUPPORTED FORMAT

=over 4

=item C<%a>

The abbreviated weekday name according to the current locale.

=item C<%A>

The full weekday name according to the current locale.

=item C<%b>

The abbreviated month name according to the current locale.

=item C<%B>

The full month name according to the current locale.

=item C<%c>

The preferred date and time representation for the current locale.

=item C<%C>

The century number (year/100) as a 2-digit integer. (SU)

=item C<%d>

The day of the month as a decimal number (range 01 to 31).

=item C<%D>

Equivalent to C<%m/%d/%y>. (for Americans only: Americans should note that in
other countries C<%d/%m/%y> is rather common. This means that in international
context this format is ambiguous and should not be used.) (SU)

=item C<%e>

Like C<%d>, the day of the month as a decimal number, but a leading zero is
replaced by a space. (SU)

=item C<%E>

Modifier: use alternative format, see below. (SU)

=item C<%F>

Equivalent to C<%Y-%m-%d> (the ISO 8601 date format). (C99)

=item C<%G>

The ISO 8601 week-based year with century as a decimal number. The
4-digit year corresponding to the ISO week number (see C<%V>). This has the
same format and value as %Y, except that if the ISO week number belongs to the
previous or next year, that year is used instead. (TZ)

=item C<%g>

Like C<%G>, but without century, that is, with a 2-digit year (00-99). (TZ)

=item C<%h>

Equivalent to C<%b>. (SU)

=item C<%H>

The hour as a decimal number using a 24-hour clock (range 00 to 23).

=item C<%I>

The hour as a decimal number using a 12-hour clock (range 01 to 12).

=item C<%j>

The day of the year as a decimal number (range 001 to 366).

=item C<%k>

The hour (24-hour clock) as a decimal number (range 0 to 23); single digits
are preceded by a blank. (See also C<%H>.) (TZ)

=item C<%l>

The hour (12-hour clock) as a decimal number (range 1 to 12); single digits
are preceded by a blank. (See also C<%I>.) (TZ)

=item C<%m>

The month as a decimal number (range 01 to 12).

=item C<%M>

The minute as a decimal number (range 00 to 59).

=item C<%n>

A newline character. (SU)

=item C<%N>

Nanoseconds (range 000000000 to 999999999). It is a non-POSIX extension and
outputs a nanoseconds if there is floating seconds argument.

=item C<%O>

Modifier: use alternative format, see below. (SU)

=item C<%p>

Either "AM" or "PM" according to the given time value, or the corresponding
strings for the current locale. Noon is treated as "PM" and midnight as "AM".

=item C<%P>

Like C<%p> but in lowercase: "am" or "pm" or a corresponding string for the
current locale. (GNU)

=item C<%r>

The time in a.m. or p.m. notation. In the POSIX locale this is equivalent to
C<%I:%M:%S %p>. (SU)

=item C<%R>

The time in 24-hour notation (%H:%M). (SU) For a version including the
seconds, see C<%T> below.

=item C<%s>

The number of seconds since the Epoch, 1970-01-01 00:00:00 +0000 (UTC). (TZ)

=item C<%S>

The second as a decimal number (range 00 to 60). (The range is up to 60 to
allow for occasional leap seconds.)

=item C<%t>

A tab character. (SU)

=item C<%T>

The time in 24-hour notation (C<%H:%M:%S>). (SU)

=item C<%u>

The day of the week as a decimal, range 1 to 7, Monday being 1. See also
C<%w>. (SU)

=item C<%U>

The week number of the current year as a decimal number, range 00 to 53,
starting with the first Sunday as the first day of week 01. See also C<%V> and
C<%W>.

=item C<%V>

The ISO 8601 week number of the current year as a decimal number,
range 01 to 53, where week 1 is the first week that has at least 4 days in the
new year. See also C<%U> and C<%W>. (SU)

=item C<%w>

The day of the week as a decimal, range 0 to 6, Sunday being 0. See also
C<%u>.

=item C<%W>

The week number of the current year as a decimal number, range 00 to 53,
starting with the first Monday as the first day of week 01.

=item C<%x>

The preferred date representation for the current locale without the time.

=item C<%X>

The preferred time representation for the current locale without the date.

=item C<%y>

The year as a decimal number without a century (range 00 to 99).

=item C<%Y>

The year as a decimal number including the century.

=item C<%z>

The C<+hhmm> or C<-hhmm> numeric timezone (that is, the hour and minute offset
from UTC). (SU)

=item C<%Z>

The timezone or name or abbreviation.

=item C<%%>

A literal C<%> character.

=back

C<%E[cCxXyY]> and C<%O[deHImMSuUVwWy]> are not supported, just remove E and O prefix.

=head1 SEE ALSO

=over 4

=item L<POSIX::strftime::GNU>

POSIX::strftime::Compiler is built on POSIX::strftime::GNU::PP code

=item L<POSIX>

=item L<Apache::LogFormat::Compiler>

=back

=head1 LICENSE

Copyright (C) Masahiro Nagano.

Format specification is based on strftime(3) manual page which is a part of the Linux man-pages project.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

