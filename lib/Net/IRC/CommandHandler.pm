use v6;

enum RequiredIntro is export <
	NONE
	NICK
	PREFIX
	EITHER
	BOTH
	>;

role Net::IRC::CommandHandler {
	has Str $.prefix is rw = '!';
	has RequiredIntro $.required-intro is rw = EITHER;

	method recognized($handler: $ev) {
		return $ev.cache<CommandHandler>{$handler.prefix} //= (gather {
			$ev.what ~~ token {
				# Intro
				^
				[ \s* $<nick>=("$ev.state()<nick>") [ ':' | ',' | \s ] ]? \s*
				[ $<prefix>=("$handler.prefix()") \s* ]?

				# Actual command (and optional params)
				$<command>=(\w+) [ <?> | \s+ $<params>=(.*) ]
				$
			} or take False;

			# Let private chat act as specifying the bot's nick
			my $nick = $<nick> || $ev.where eq $ev.state<nick>;

			given $.required-intro {
				when NICK   { take False unless $nick		   }
				when PREFIX { take False unless $<prefix>	   }
				when EITHER { take False unless $<prefix> || $nick }
				when BOTH   { take False unless $<prefix> && $nick }
			}

			take $/;
		})[0];
	}

	multi method said ($ev where { $/ := $.recognized($ev) }) {
		self.*"command_$<command>"($ev, $/);
	}

	method usage($ev, $usage) {
		$ev.msg("Usage: $usage");
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4
