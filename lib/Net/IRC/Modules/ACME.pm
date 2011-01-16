use v6;
module Modules::ACME;

class Eightball {
	my @replies = "Probably not", "Nope", "Never", "Not a chance", "Doubt it", "No", 
	"Answer hazy.. Oh wait there it is. It's a no.", "Yes.. Haha just kidding. No.", 
	"No.", "Aww hell naw";
	
	multi method said ( $ev where {.what ~~ /^\!8ball <.ws> .+/} ) {
		$ev.msg("{$ev.who<nick>}: { @replies.pick }");
	}
}

class Unsmith {
	has @replies = open('Net/IRC/Modules/unsmith').lines;
	my regex sad {
		[ ^|\s ]
		[ [ [':'|'='] <[\<\(\[]> ] | [ 'un'?'smith' ] | 'sad''face'? ]
		[ $|\s ]
	}
	multi method said ( $ev where {.what ~~ &sad} ) {
		$ev.msg(@replies.pick);
	}
}
