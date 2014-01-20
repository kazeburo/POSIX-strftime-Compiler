use Benchmark qw/:all/;
use POSIX qw//;
use POSIX::strftime::Compiler;

my $fmt = '%d/%b/%Y:%T %z';

my @abbr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my $t = time;

sub with_sprintf {
    my $tz = POSIX::strftime('%z',@_);
    sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $_[3], $abbr[$_[4]], $_[5]+1900, 
        $_[2], $_[1], $_[0], $tz;
}
my $psc = POSIX::strftime::Compiler->new($fmt);
cmpthese(timethese(-1, {
    'compiler' => sub {
        $psc->to_string(localtime($t));
    },
    'compiler_function' => sub {
        POSIX::strftime::Compiler::strftime($fmt, localtime($t));
    },
    'posix_and_locale' => sub {
        my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
        POSIX::setlocale(&POSIX::LC_ALL, 'C');
        POSIX::strftime($fmt,localtime($t));
        POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
    },
#    'compiler_wo_cache' => sub {
#        my $compiler2 = POSIX::strftime::Compiler->new($fmt);
#        $compiler2->to_string(localtime($t));
#    },
    'sprintf' => sub {
        with_sprintf(localtime($t));
    },
}));


__END__
Benchmark: running compiler, compiler_function, posix_and_locale, sprintf for at least 1 CPU seconds...
  compiler:  1 wallclock secs ( 1.06 usr +  0.00 sys =  1.06 CPU) @ 190933.96/s (n=202390)
compiler_function:  1 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 187398.15/s (n=202390)
posix_and_locale:  2 wallclock secs ( 1.14 usr +  0.00 sys =  1.14 CPU) @ 68592.98/s (n=78196)
   sprintf:  1 wallclock secs ( 1.02 usr +  0.00 sys =  1.02 CPU) @ 210822.55/s (n=215039)
                      Rate posix_and_locale compiler_function compiler   sprintf
posix_and_locale   68593/s               --              -63%     -64%      -67%
compiler_function 187398/s             173%                --      -2%      -11%
compiler          190934/s             178%                2%       --       -9%
sprintf           210823/s             207%               12%      10%        --
