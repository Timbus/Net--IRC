module Modules::Autoident;

role Autoident[Str $nspassword] {
	multi method connected {
		say "Identifying with nickserv..";
		$.sendln("NS IDENTIFY $nspassword");
	}
}
