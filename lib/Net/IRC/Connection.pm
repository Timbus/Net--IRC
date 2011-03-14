use v6;

class Net::IRC::Connection is IO::Socket::INET {
	#State variables.
	method sendln(Str $string) {
		self.send($string~"\c13\c10");
	}
}
