use Benchmark qw/:all/;
use POSIX qw//;
use POSIX::strftime::Compiler;

my $fmt = '%d/%b/%Y:%T %z';

my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $t = time;

sub with_sprintf {
    my $tz = POSIX::strftime('%z',@_);
    sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $_[3], $abbr[$_[4]], $_[5]+1900, 
        $_[2], $_[1], $_[0], $tz;
}

cmpthese(timethese(-1, {
    'compiler' => sub {
        POSIX::strftime::Compiler::strftime($fmt, localtime($t));
    },
    'posix_and_locale' => sub {
        my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
        POSIX::setlocale(&POSIX::LC_ALL, 'C');
        POSIX::strftime($fmt,localtime($t));
        POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
    },
    'compiler_wo_cache' => sub {
        my $compiler2 = POSIX::strftime::Compiler->new($fmt);
        $compiler2->to_string(localtime($t));
    },
    'sprintf' => sub {
        with_sprintf(localtime($t));
    },
}));


__END__
Benchmark: running compiler, compiler_wo_cache, posix_and_locale, sprintf for at least 1 CPU seconds...
  compiler:  1 wallclock secs ( 1.17 usr +  0.00 sys =  1.17 CPU) @ 182781.20/s (n=213854)
compiler_wo_cache:  2 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 13397.20/s (n=14335)
posix_and_locale:  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 68265.71/s (n=71679)
   sprintf:  1 wallclock secs ( 1.13 usr +  0.00 sys =  1.13 CPU) @ 202986.73/s (n=229375)
                      Rate compiler_wo_cache posix_and_locale compiler   sprintf
compiler_wo_cache  13397/s                --             -80%     -93%      -93%
posix_and_locale   68266/s              410%               --     -63%      -66%
compiler          182781/s             1264%             168%       --      -10%
sprintf           202987/s             1415%             197%      11%        --
