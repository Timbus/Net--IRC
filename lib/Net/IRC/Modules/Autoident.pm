use v6;
unit module Net::IRC::Modules::Autoident;

#= Automatically identify with Nickserv
class Net::IRC::Modules::Autoident {
	has $.password = die "Need to tell Autoident your password if you want it to work!";
	multi method connected($ev) {
		say "Identifying with nickserv..";
		$ev.conn.sendln("NS IDENTIFY $.password", scrubbed => 'NS IDENTIFY ...');
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4

