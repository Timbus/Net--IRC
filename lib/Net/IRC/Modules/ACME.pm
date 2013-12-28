use v6;
use Net::IRC::CommandHandler;

module Net::IRC::Modules::ACME;

#= Emulate a (rather negative) Magic 8 Ball
class Net::IRC::Modules::ACME::Eightball {
	my @replies = "Probably not", "Nope", "Never", "Not a chance", "Doubt it", "No", 
	"Answer hazy.. Oh wait there it is. It's a no.", "Yes.. Haha just kidding. No.", 
	"No.", "Aww hell naw";
	
	multi method said ( $ev where {.what ~~ /^\!8ball <.ws> .+/} ) {
		$ev.msg("{$ev.who}: { @replies.pick }");
	}
}

#= Print unsmith quotes
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

#= Bark like a dog
class Net::IRC::Modules::ACME::Bark::LikeADog does Net::IRC::CommandHandler {
	#= Use 'bark' to see me bark like a dog
	method command_bark($ev, $match) {
		$ev.msg("Woof!");
	}
}

#= Bark like a tree
class Net::IRC::Modules::ACME::Bark::LikeATree does Net::IRC::CommandHandler {
	#= Use 'bark' to see me describe tree bark
	method command_bark($ev, $match) {
		$ev.msg("The bark is smooth and brown.");
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4

