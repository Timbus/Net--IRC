module Modules::ACME;

class Eightball {
	multi method said ( $msg where /^\!8ball <.ws> .+/, $from, $channel ) { #/
		my @replies = "Probably not", "Nope", "Never", "Not a chance", "Doubt it", "No", 
		"Answer hazy.. Oh wait there it is. It's a no.", "Yes.. Haha just kidding. No.", 
		"No.", "Aww hell naw";
		$.msg("$from: { @replies.pick }", $channel);
	}
}

class Unsmith {
	has @replies = open('Modules/unsmith').lines;
	has regex sad {
		[ ^|\s ]
		[':<' | ':(' | '>:' | '):' | [ 'un'?'smith' ] | 'sad''face'? ]
		[ $|\s ]
	}
	multi method said ( $msg where &sad, $, $channel ) {
		$.msg(@replies.pick, $channel);
	}
}
