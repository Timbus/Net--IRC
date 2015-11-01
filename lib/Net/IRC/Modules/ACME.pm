use v6;
use Net::IRC::CommandHandler;

unit module Net::IRC::Modules::ACME;

#= Enjoy delicious bot snacks
class Net::IRC::Modules::ACME::Botsnack does Net::IRC::CommandHandler {
	my @replies = "Mmm, delicious.", "Yummy, thanks!", ":-)", "☺",
	"Om nom nom nom", "Tasty!", "Nothing quite like a well-earned snack!";

	#= Use 'botsnack' to toss me a delicious bot snack
	method botsnack ( $ev, $match ) is cmd {
		$ev.msg("{$ev.who}: { @replies.pick }");
	}
}

#= Emulate a (rather negative) Magic 8 Ball
class Net::IRC::Modules::ACME::Eightball does Net::IRC::CommandHandler {
	my @replies = "Probably not", "Nope", "Never", "Not a chance", "Doubt it", "No",
	"Answer hazy ... oh wait there it is.  It's a no.", "Yes!  Haha, just kidding.  No.",
	"No.", "Aww hell naw";

	#= Use '8ball' to consult the Magic 8 Ball
	method eightball ( $ev, $match ) is cmd(:name('8ball')) {
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
	method bark($ev, $match) is cmd {
		$ev.msg("Woof!");
	}
}

#= Bark like a tree
class Net::IRC::Modules::ACME::Bark::LikeATree does Net::IRC::CommandHandler {
	#= Use 'bark' to see me describe tree bark
	method bark($ev, $match) is cmd {
		$ev.msg(["The bark is smooth and brown.", "[Rustling intensifies]"]);
	}
}

#= Use a rotated alphabet to (de)obfuscate (ASCII) text
class Net::IRC::Modules::ACME::Rot13 does Net::IRC::CommandHandler {
	#= Use 'rot13 <message>' to (de)obfuscate a message with rot13
	method rot13($ev, $match) is cmd {
		my $message = $match<params>.trans('A..Z' => 'N..ZA..M',
						   'a..z' => 'n..za..m');
		$ev.msg($message);
	}
}

#= Give someone a cuddle or hug
class Net::IRC::Modules::ACME::Hug does Net::IRC::CommandHandler {
	#= Use 'hug <nick>' to send someone a hug, or 'hug me' to ask for one
	method hug($ev, $match) is cmd {
		# Original hug logic from https://github.com/moritz/hugme/blob/master/hugme.pl#L85
		my $recipient = $match<params> eq 'me' ?? $ev.who !! $match<params>;
		my $extra = '';
		$extra ~= ' and blushes'  if rand > .95;
		$extra ~= "; {$ev.who}++" if rand > .99;
		$ev.act("$match<command>s $recipient$extra");
	}

	#= Use 'cuddle <nick>' to send someone a cuddle, or 'cuddle me' to ask for one
	method cuddle($ev, $match) is cmd {
		self.hug($ev, $match);
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4

