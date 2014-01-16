use Benchmark qw/:all/;
use POSIX qw/strftime/;
use POSIX::strftime::Compiler;
use HTTP::Date qw//;

my $fmt = '%d/%b/%Y:%T %z';
my $compiler = POSIX::strftime::Compiler->new($fmt);
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $t = time;

sub with_sprintf {
    my $tz = '+0900';
    sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $_[3], $abbr[$_[4]], $_[5]+1900, 
        $_[2], $_[1], $_[0], $tz;
}

cmpthese(timethese(-1, {
    'compiler' => sub {
        $compiler->to_string(localtime($t));
    },
    'compiler_strftime' => sub {
        POSIX::strftime::Compiler::strftime($fmt, localtime($t));
    },
    'posix' => sub {
        POSIX::strftime($fmt,localtime($t));
    },
#    'compiler_wo_cache' => sub {
#        my @t = localtime;
#        my $compiler2 = Time::Format::Compiler->new($fmt);
#        $compiler2->to_string(@t);
#    },
#    'http_date' => sub {
#        HTTP::Date::time2str($t);
#    },
#    'sprintf' => sub {
#        with_sprintf(localtime($t));
#    },
}));


__END__
% perl -Ilib eg/benchmark.pl   
Benchmark: running compiler, compiler_strftime, posix for at least 1 CPU seconds...
  compiler:  0 wallclock secs ( 1.10 usr +  0.01 sys =  1.11 CPU) @ 140893.69/s (n=156392)
compiler_strftime:  1 wallclock secs ( 1.01 usr +  0.00 sys =  1.01 CPU) @ 143735.64/s (n=145173)
     posix:  1 wallclock secs ( 1.14 usr + -0.00 sys =  1.14 CPU) @ 196415.79/s (n=223914)
                      Rate          compiler compiler_strftime             posix
compiler          140894/s                --               -2%              -28%
compiler_strftime 143736/s                2%                --              -27%
posix             196416/s               39%               37%                --


## without '%z'
Benchmark: running compiler, compiler_strftime, posix for at least 1 CPU seconds...
  compiler:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 459364.49/s (n=491520)
compiler_strftime:  1 wallclock secs ( 1.12 usr +  0.00 sys =  1.12 CPU) @ 438857.14/s (n=491520)
     posix:  1 wallclock secs ( 1.02 usr +  0.00 sys =  1.02 CPU) @ 240941.18/s (n=245760)
                      Rate             posix compiler_strftime          compiler
posix             240941/s                --              -45%              -48%
compiler_strftime 438857/s               82%                --               -4%
compiler          459364/s               91%                5%                --

