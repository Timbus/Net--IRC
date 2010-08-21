module Modules::ACME;

class Eightball {
	multi method said ( $ev where /^\!8ball <.ws> .+/ ) { #/
		my @replies = "Probably not", "Nope", "Never", "Not a chance", "Doubt it", "No", 
		"Answer hazy.. Oh wait there it is. It's a no.", "Yes.. Haha just kidding. No.", 
		"No.", "Aww hell naw";
		$ev.msg("{$ev.who}: { @replies.pick }");
	}
}

class Unsmith {
	has @replies = open('Modules/unsmith').lines;
	has regex sad {
		[ ^|\s ]
		[':<' | ':(' | '>:' | '):' | [ 'un'?'smith' ] | 'sad''face'? ]
		[ $|\s ]
	}
	multi method said ( $ev where &sad) {
		$ev.msg(@replies.pick);
	}
}
