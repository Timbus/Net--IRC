module Modules::Autoident;

class Autoident {
	has $password = die "Need no tell Autoident your password if you want it to work!";
	multi method connected {
		say "Identifying with nickserv..";
		$.sendln("NS IDENTIFY $password");
	}
}
