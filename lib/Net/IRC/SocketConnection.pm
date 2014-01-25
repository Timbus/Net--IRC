use v6;

use Net::IRC::Logger;


class Net::IRC::SocketConnection {
    has Net::IRC::Logger $.log;
    has IO::Socket       $.socket;
    has Channel          $.to-socket;
    has Supply           $.recv;
    has Supply           $.get;
    has Bool             $!recv-done;
    has buf8             $!buffer = buf8.new;

    multi method new(:$host!, :$log = $*LOG, *%socket-options) {
        $log.info("Making socket connection to $host");
        my $socket = IO::Socket::INET.new(:$host, |%socket-options);
        self.new($socket, $log);
    }

    multi method new(IO::Socket $socket, Net::IRC::Logger $log = $*LOG) {
        $log.debug('Building Net::IRC::SocketConnection');
        my $to-socket = Channel.new;
        my $recv = Supply.new;
        my $self = self.bless(:$log, :$socket, :$to-socket, :$recv);

        $self!start-threads;
        $self;
    }

    method !start-threads() {
        # Line splitting assumptions:
        # * Both lines and encoding groups can be split across chunks
        # * The line separator can't be confused with a partial encoding group
        # * Decoding is not horribly slow (so we can repeat it over incomplete
        #   lines until we get the line separator without performance death)
        # * Encoding isn't horribly slow either
        $.log.info('Preparing socket supplies');
        $!get := on -> $out {
            $!recv => sub ($chunk) {
                $!buffer ~= $chunk;
                my $enc     := $!socket.encoding;
                my $sep     := $!socket.input-line-separator;
                my $decoded := $!buffer.decode($enc);
                my @lines   := $decoded.split($sep);
                if @lines > 1 {
                    # Drop final partial line, and forward on the whole ones
                    @lines.pop;
                    $out.more($_) for @lines;

                    # Remove already-forwarded portion of buffer
                    my $forwarded := @lines.push('').join($sep).encode($enc);
                    my $to-remove  = $forwarded.elems;
                    $!buffer .= subbuf($to-remove);
                }
            }
        };
        $!recv.tap: {;}, done => { $!recv-done = True;
                                   $*LOG.info('recv supply closed') };

        start {
            $.log.info('Starting socket -> supplies thread');

            loop {
                my $chunk = $.socket.recv(:bin);
                if $chunk.elems {
                    $.log.debug("<-- $chunk.elems() bytes");
                    $.recv.more($chunk);
                }
                else {
                    $.log.info('Exiting socket -> supplies thread');
                    $.recv.done;
                    last;
                }
            }
        }

        start {
            $.log.info('Starting channel -> socket thread');

            loop {
                winner $.to-socket {
                    more * { $.log.debug("»»» $_.value()");
                             $.socket.write($_.key) }
                    done * { $.log.info('Exiting channel -> socket thread');
                             last }
                }
            }
        }
    }

    multi method send(Blob $data) {
        $.to-socket.send: $data => "$data.elems() bytes";
    }

    multi method send(Str $text, :$scrubbed = $text) {
        $.to-socket.send: $text.encode('utf8') => $scrubbed;
    }

    multi method sendln(Str $text, :$scrubbed = $text) {
        # This should be an *output* line separator, but that doesn't exist.
        my $sep := $.socket.input-line-separator;
        $.to-socket.send: "$text$sep".encode('utf8') => $scrubbed;
    }

    method close(:$to is copy, :$from is copy) {
        my $both = !($to ?^ $from);
        $to    ||= $both;
        $from  ||= $both;
        $.log.info("Closing socket (to: {?$to}, from: {?$from})");

        $.to-socket.close if $to;
        $.recv.done       if $from && !$!recv-done;
        $.socket.close    if $.to-socket.closed && $!recv-done;
    }
}
