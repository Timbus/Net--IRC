use v6;

BEGIN die "Requires threads support; try running with rakudo-jvm or rakudo-moar."
    if ::('Thread') ~~ Failure;

enum LogLevel is export <
    DEBUG
    INFO
    NOTICE
    WARNING
    ERROR
    CRITICAL
    ALERT
    EMERGENCY
>;

class Net::IRC::Logger {
    has LogLevel   $.min-level;
    has IO::Path   $.path;
    has IO::Handle $!handle;
    has Channel    $!channel;

    submethod BUILD(:$!min-level, :$!path, :$!handle, :$!channel) {}

    method new(Cool $path is copy, LogLevel :$min-level = INFO) {
        $path      .= path;
        my $handle  = $path.open(:w);
        my $channel = Channel.new;
        my $self    = self.bless(:$min-level, :$path, :$handle, :$channel);

        start {
            loop {
                winner $channel {
                    # XXXX: Would normally like to open/append/close for
                    #       each log entry so that log rotation works well,
                    #       but right now this is REALLY SLOW (~100x slower)

                    more * { $handle.print(/\n $/ ?? $_ !! "$_\n")  }
                    done * { $handle.close; last }
                }
            }
        }

        GLOBAL::<$LOG> //= $self;
        $self;
    }

    method timestamp($time = now) {
        my $dt = DateTime.new($time);
        sprintf('%4d-%02d-%02d %02d:%02d:%02d.%03d',
                $dt.year, $dt.month, $dt.day,
                $dt.hour, $dt.minute, $dt.second,
                Int($dt.second * 1000 % 1000));
    }

    method log(LogLevel $level, $message) {
        return if !self || $level < $.min-level;

        my $icon   = $level ~~ EMERGENCY ?? '!' !! $level.Str.substr(0, 1);
        my $loads  = $*SCHEDULER.loads.join: ',';
        my $prefix = "$icon $loads $.timestamp: ";

        $!channel.send: $prefix ~ $message;
    }

    method debug($message) { self.log(DEBUG,     $message) }
    method info($message)  { self.log(INFO,      $message) }
    method note($message)  { self.log(NOTICE,    $message) }
    method warn($message)  { self.log(WARNING,   $message) }
    method error($message) { self.log(ERROR,     $message) }
    method crit($message)  { self.log(CRITICAL,  $message) }
    method alert($message) { self.log(ALERT,     $message) }
    method emerg($message) { self.log(EMERGENCY, $message) }
}


# Global $*LOG variable
# Default to do-nothing logger, replaced by first Net::IRC::Logger.new()
GLOBAL::<$LOG> = Net::IRC::Logger;
