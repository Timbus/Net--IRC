use v6;
module Net::IRC::Modules::ACME;

class Net::IRC::Modules::ACME::Eightball {
	my @replies = "Probably not", "Nope", "Never", "Not a chance", "Doubt it", "No", 
	"Answer hazy.. Oh wait there it is. It's a no.", "Yes.. Haha just kidding. No.", 
	"No.", "Aww hell naw";
	
	multi method said ( $ev where {.what ~~ /^\!8ball <.ws> .+/} ) {
		$ev.msg("{$ev.who}: { @replies.pick }");
	}
}

class Net::IRC::Modules::ACME::Unsmith {
	has @replies = open('Net/IRC/Modules/unsmith').lines;
# XXX: Can't use this. Seems to be some kind of rakudo bug.
#	my regex sad {
#		[ ^|\s ]
#		[ [ [':'|'='] <[\<\(\[]> ] | [ 'un'?'smith' ] | 'sad''face'? ]
#		[ $|\s ]
#	}
	multi method said ( $ev where { 
		.what ~~ m/
			[ ^|\s ]
			[ [ [':'|'='] <[\<\(\[]> ] | [ 'un'?'smith' ] | 'sad''face'? ]
			[ $|\s ] 
		/}) {
		
		$ev.msg(@replies.pick);
	}
}
