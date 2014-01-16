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
    'http_date' => sub {
        HTTP::Date::time2str($t);
    },
    'sprintf' => sub {
        with_sprintf(localtime($t));
    },
}));


__END__
% perl -Ilib eg/benchmark.pl   
Benchmark: running compiler, compiler_strftime, http_date, posix, sprintf for at least 1 CPU seconds...
  compiler:  1 wallclock secs ( 1.12 usr +  0.00 sys =  1.12 CPU) @ 409600.00/s (n=458752)
compiler_strftime:  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 371358.72/s (n=404781)
 http_date:  1 wallclock secs ( 1.00 usr +  0.00 sys =  1.00 CPU) @ 573439.00/s (n=573439)
     posix:  1 wallclock secs ( 1.13 usr +  0.00 sys =  1.13 CPU) @ 219298.23/s (n=247807)
   sprintf:  0 wallclock secs ( 1.00 usr +  0.01 sys =  1.01 CPU) @ 567761.39/s (n=573439)
                      Rate    posix compiler_strftime compiler sprintf http_date
posix             219298/s       --              -41%     -46%    -61%      -62%
compiler_strftime 371359/s      69%                --      -9%    -35%      -35%
compiler          409600/s      87%               10%       --    -28%      -29%
sprintf           567761/s     159%               53%      39%      --       -1%
http_date         573439/s     161%               54%      40%      1%        --
