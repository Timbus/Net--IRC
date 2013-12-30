use v6;
use Net::IRC::CommandHandler;

module Net::IRC::Modules::ACME;

#= Enjoy delicious bot snacks
class Net::IRC::Modules::ACME::Botsnack does Net::IRC::CommandHandler {
	my @replies = "Mmm, delicious.", "Yummy, thanks!", ":-)", "☺",
	"Om nom nom nom", "Tasty!", "Nothing quite like a well-earned snack!";
	
	#= Use 'botsnack' to toss me a delicious bot snack
	method command_botsnack ( $ev, $match ) {
		$ev.msg("{$ev.who}: { @replies.pick }");
	}
}

#= Emulate a (rather negative) Magic 8 Ball
class Net::IRC::Modules::ACME::Eightball does Net::IRC::CommandHandler {
	my @replies = "Probably not", "Nope", "Never", "Not a chance", "Doubt it", "No",
	"Answer hazy ... oh wait there it is.  It's a no.", "Yes!  Haha, just kidding.  No.",
	"No.", "Aww hell naw";
	
	#= Use '8ball' to consult the Magic 8 Ball
	method command_8ball ( $ev, $match ) {
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

#= Use a rotated alphabet to (de)obfuscate (ASCII) text
class Net::IRC::Modules::ACME::Rot13 does Net::IRC::CommandHandler {
	#= Use 'rot13 <message>' to (de)obfuscate a message with rot13
	method command_rot13($ev, $match) {
		my $message = $match<params>.trans('A..Z' => 'N..ZA..M',
						   'a..z' => 'n..za..m');
		$ev.msg($message);
	}
}

#= Give someone a cuddle or hug
class Net::IRC::Modules::ACME::Hug does Net::IRC::CommandHandler {
	#= Use 'hug <nick>' to send someone a hug, or 'hug me' to ask for one
	method command_hug($ev, $match) {
		# Original hug logic from https://github.com/moritz/hugme/blob/master/hugme.pl#L85
		my $recipient = $match<params> eq 'me' ?? $ev.who !! $match<params>;
		my $extra = '';
		$extra ~= ' and blushes'  if rand > .95;
		$extra ~= "; {$ev.who}++" if rand > .99;
		$ev.act("$match<command>s $recipient$extra");
	}

	#= Use 'cuddle <nick>' to send someone a cuddle, or 'cuddle me' to ask for one
	method command_cuddle($ev, $match) {
		self.command_hug($ev, $match);
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4

