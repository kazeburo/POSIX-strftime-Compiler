package POSIX::strftime::Compiler;

use 5.008004;
use strict;
use warnings;
use Carp;
use Time::Local qw//;
use POSIX qw//;
use base qw/Exporter/;

our $VERSION = "0.06";
our @EXPORT_OK = qw/strftime/;

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
};

BEGIN {
    *tzoffset = \&_tzoffset;
    *tzname = \&_tzname;

    if (eval { require POSIX::strftime::GNU::XS; 1; }) {
        no warnings 'redefine';
        if ( POSIX::strftime::GNU::XS::strftime('%z', localtime) =~ /^[+-]\d{4}$/) {
            *tzoffset = sub { POSIX::strftime::GNU::XS::strftime("%z", @_) };
        }
        if ( length POSIX::strftime::GNU::XS::strftime('%Z', localtime) ) {
            *tzname = sub { POSIX::strftime::GNU::XS::strftime("%Z", @_) };
        }
    }
}


# copy from POSIX/strftime/GNU/PP.pm and modify
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

sub _tzoffset {
    my @t = @_;

    # Normalize @t array, we need seconds without frac
    $t[SEC] = int $t[SEC];

    my $diff = (exists $ENV{TZ} and $ENV{TZ} eq 'GMT')
             ? 0
             : Time::Local::timegm(@t) - Time::Local::timelocal(@t);
    sprintf '%+03d%02u', $diff/60/60, $diff/60%60;
}

sub _tzname {
    my @t = @_;

    return 'GMT' if exists $ENV{TZ} and $ENV{TZ} eq 'GMT';

    my $diff = tzoffset(@t);
    $diff =~ s!(\d\d)(\d\d)$!$1:$2!;
    $diff =~ s!:00!!g;

    my @t1 = my @t2 = @t;
    @t1[3,4] = (1, 1);  # winter
    @t2[3,4] = (1, 7);  # summer

    my $diff1 = tzoffset(@t1);
    $diff1 =~ s!(\d\d)(\d\d)$!$1:$2!;
    $diff1 =~ s!:00!!g;
    my $diff2 = tzoffset(@t2);
    $diff2 =~ s!(\d\d)(\d\d)$!$1:$2!;
    $diff2 =~ s!:00!!g;

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
    @t = gmtime Time::Local::timegm(@t);

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

our %rules = (
    '%' => [q!'%'!],
    'a' => [q!$weekday_abbr[$_[WDAY]]!],
    'A' => [q!$weekday_name[$_[WDAY]]!],
    'b' => [q!$month_abbr[$_[MONTH]]!],
    'B' => [q!$month_name[$_[MONTH]]!],
    'c' => [q!$weekday_abbr[$_[WDAY]] . ' ' . $month_abbr[$_[MONTH]] . ' ' . substr(' '.$_[DAY],-2) . ' %H:%M:%S %Y'!],
    'C' => [q!substr('0'.int(($_[YEAR]+1900)/100), -2)!],  #century
    'h' => [q!$month_abbr[$_[MONTH]]!],
    'N' => [q!substr(sprintf('%.9f', $_[SEC] - int $_[SEC]), 2)!],
    'n' => [q!"\n"!],
    'p' => [q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM"!],
    'P' => [q!$_[HOUR] > 0 && $_[HOUR] < 13 ? "am" : "pm"!],
    'r' => [q!sprintf('%02d:%02d:%02d %s',$_[HOUR]%12 || 1, $_[MIN], $_[SEC], $_[HOUR] > 0 && $_[HOUR] < 13 ? "AM" : "PM")!],
    't' => [q!"\t"!],
    'x' => [q!'%m/%d/%y'!],
    'X' => [q!'%H:%M:%S'!],
);

if ( $^O eq 'MSWin32' || $^O eq 'Cygwin' ) {
    %rules = (
        %rules,
        'D' => [q!'%m/%d/%y'!],
        'F' => [q!'%Y-%m-%d'!],
        'G' => [q!substr('0000'. isoyearnum(@_), -4)!],
        'R' => [q!'%H:%M'!],
        'T' => [q!'%H:%M:%S'!],
        'V' => [q!substr('0'.isoweeknum(@_),-2)!],
        'e' => [q!substr(' '.$_[DAY],-2)!],
        'g' => [q!substr('0'.isoyearnum(@_)%100,-2)!],
        'k' => [q!substr(' '.$_[HOUR],-2)!],
        'l' => [q!substr(' '.($_[HOUR]%12 || 1),-2)!],
        's' => [q!int(Time::Local::timegm(@_))!],
        'u' => [q!$_[WDAY] || 7!],
        'z' => [q!tzoffset(@_)!],
        'Z' => [q!tzname(@_)!],
    );
}

my $char_handler = sub {
    my ($char) = @_;
    die unless exists $rules{$char};
    my ($code) = @{$rules{$char}};
    q|! . | . $code . q| . q!|;
};

sub compile {
    my ($fmt) = @_;

    $fmt =~ s/!/\\!/g;
    my $rule_chars = join "", keys %rules;
    $fmt =~ s!\%E([cCxXyY])!%$1!g;
    $fmt =~ s!\%O([deHImMSuUVwWy])!%$1!g;
    $fmt =~ s!
        (?:
             \%([$rule_chars])
        )
    ! $char_handler->($1) !egx;

    my @weekday_name = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    my @weekday_abbr = qw(Sun Mon Tue Wed Thu Fri Sat);
    my @month_name = qw(January February March April May June July August September October November December);
    my @month_abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

    $fmt = q~sub {
        if ( @_ != 9  && @_ != 6 ) {
            Carp::croak 'Usage: strftime(sec, min, hour, mday, mon, year, wday = -1, yday = -1, isdst = -1)';
        }
        POSIX::strftime(q!~ . $fmt . q~!,@_);
    }~;
    my $sub = eval $fmt; ## no critic
    die $@ ."\n===\n".$fmt if $@;
    wantarray ? ($sub,$fmt) : $sub;
}

my %STRFTIME;
sub strftime {
    my $fmt = shift;
    $STRFTIME{$fmt} ||= compile($fmt);
    $STRFTIME{$fmt}->(@_);
}

sub new {
    my $class = shift;
    my $fmt = shift;
    my ($sub,$code) = compile($fmt);
    bless [$sub,$code], $class;
}

sub to_string {
    my $self = shift;
    $self->[0]->(@_);
}

sub code_ref {
    my $self = shift;
    $self->[0];
}

1;
__END__

=encoding utf-8

=head1 NAME

POSIX::strftime::Compiler - GNU C library compatible strftime for loggers and servers

=head1 SYNOPSIS

    use POSIX::strftime::Compiler qw/strftime/;

    say strftime('%a, %d %b %Y %T %z',localtime):
    
    my $psc = POSIX::strftime::Compiler->new($fmt);
    say $psc->to_string(localtime);

=head1 DESCRIPTION

POSIX::strftime::Compiler provides GNU C library compatible strftime(3). But this module will not affected
by the system locale.  This feature is useful when you want to write loggers, servers and portable applications.

For generate same result strings on any locale, POSIX::strftime::Compiler wraps POSIX::strftime and 
converts some format characters to perl code

=head1 FUNCTION

=over 4

=item strftime($fmt:String, @time)

Generate formatted string from a format and time.

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  strftime('%d/%b/%Y:%T %z',$sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst):

Compiled codes are stored in C<%POSIX::strftime::Compiler::STRFTIME>. This function is not exported by default.

=back

=head1 METHODS

=over 4

=item new($fmt)

create instance of POSIX::strftime::Compiler

=item to_string(@time)

Generate formatted string from time.

=back

=head1 FORMAT CHARACTERS

POSIX::strftime::Compiler supports almost all characters that GNU strftime(3) supports. 
But C<%E[cCxXyY]> and C<%O[deHImMSuUVwWy]> are not supported, just remove E and O prefix.

=head1 PERFORMANCE ISSUES ON WINDOWS

Windows and Cygwin and some system may not support C<%z> and C<%Z>. For these system, 
POSIX::strftime::Compiler calculate time zone offset and find zone name. This is not fast.
If you need performance on Windows and Cygwin, please install L<POSIX::strftime::GNU>

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

