use v6;

use Net::IRC::Logger;


class Net::IRC::SocketConnection {
    has Net::IRC::Logger $.log;
    has IO::Socket       $.socket;
    has Channel          $.to-socket;
    has Channel          $.from-socket;

    multi method new(IO::Socket $socket, Net::IRC::Logger $log = $*LOG) {
        $log.debug('Building Net::IRC::SocketConnection');
        my $to-socket   = Channel.new;
        my $from-socket = Channel.new;
        my $self = self.bless(:$log, :$socket, :$to-socket, :$from-socket);

        $log.info("Starting channel -> socket thread ...");
        start {
            loop {
                winner $to-socket {
                    more * { $log.debug("Writing $_.elems() bytes to socket");
                             $socket.write($_) }
                    done * { $log.debug("Exiting channel -> socket thread");
                             last }
                }
            }
        }

        $log.info("Starting socket -> channel thread ...");
        start {
            loop {
                my $chunk = $socket.recv(:bin);
                if $chunk.elems {
                    $log.debug("Received $chunk.elems() bytes from socket");
                    $from-socket.send($chunk);
                }
                else {
                    $log.debug("Exiting socket -> channel thread");
                    $from-socket.close;
                    last;
                }
            }
        }

        $self;
    }

    multi method new(:$host!, :$log = $*LOG, *%socket-options) {
        $log.info("Making socket connection to $host ...");
        my $socket = IO::Socket::INET.new(:$host, |%socket-options);
        self.new($socket, $log);
    }

    multi method send(Blob $data) {
        $.to-socket.send($data);
    }

    multi method send(Str $message) {
        $.to-socket.send($message.encode('utf8'));
    }

    method close(:$to, :$from) {
        my $both = !($to ?^ $from);
        $.to-socket.close   if $to   || $both;
        $.from-socket.close if $from || $both;
        $.socket.close if $.to-socket.closed && $.from-socket.closed;
    }
}
