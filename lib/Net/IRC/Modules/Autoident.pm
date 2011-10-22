use v6;
module Net::IRC::Modules::Autoident;

class Net::IRC::Modules::Autoident {
	has $password = die "Need no tell Autoident your password if you want it to work!";
	multi method connected($ev) {
		say "Identifying with nickserv..";
		$ev.conn.sendln("NS IDENTIFY $password");
	}
}
