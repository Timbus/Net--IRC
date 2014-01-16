use v6;

use Net::IRC::Logger;


class Net::IRC::SocketConnection {
    has Net::IRC::Logger $.log;
    has IO::Socket       $.socket;
    has Channel          $.to-socket;
    has Channel          $.from-socket;

    multi method new(:$host!, :$log = $*LOG, *%socket-options) {
        $log.info("Making socket connection to $host");
        my $socket = IO::Socket::INET.new(:$host, |%socket-options);
        self.new($socket, $log);
    }

    multi method new(IO::Socket $socket, Net::IRC::Logger $log = $*LOG) {
        $log.debug('Building Net::IRC::SocketConnection');
        my $to-socket   = Channel.new;
        my $from-socket = Channel.new;
        my $self = self.bless(:$log, :$socket, :$to-socket, :$from-socket);

        $self!start-threads;
        $self;
    }

    method !start-threads() {
        $.log.info('Starting channel -> socket thread');
        start {
            loop {
                winner $.to-socket {
                    more * { $.log.debug("»»» $_.value()");
                             $.socket.write($_.key) }
                    done * { $.log.info('Exiting channel -> socket thread');
                             last }
                }
            }
        }

        $.log.info('Starting socket -> channel thread');
        start {
            loop {
                my $chunk = $.socket.recv(:bin);
                if $chunk.elems {
                    $.log.debug("<-- $chunk.elems() bytes");
                    $.from-socket.send($chunk);
                }
                else {
                    $.log.info('Exiting socket -> channel thread');
                    $.from-socket.close;
                    last;
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
        $.to-socket.send: "$text\c13\c10".encode('utf8') => $scrubbed;
    }

    method close(:$to, :$from) {
        my $both = !($to ?^ $from);
        $.to-socket.close   if $to   || $both;
        $.from-socket.close if $from || $both;
        $.socket.close if $.to-socket.closed && $.from-socket.closed;
    }
}
