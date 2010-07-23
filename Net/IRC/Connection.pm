use v6;

class Net::IRC::Connection is IO::Socket::INET {
	#State variables.
	has Bool $connected = False;

	#Perl IO uses 'get' for getting a single line..
	has Str $buf = "";
	method get {
		loop {
			my ($line, $tail) = $buf.split("\c13\c10", 2);
			
			if $tail {
				$buf := $tail;
				return $line.encode('UTF-8').decode('UTF-8');
			}
		}
	}
	
	method sendln(Str $string) {
		self.send($string~"\c13\c10");
	}

    method recvp () {
        fail("Not connected!") unless $!PIO;
        return $!PIO.recv();
    }
}
