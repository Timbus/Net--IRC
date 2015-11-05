use v6;

enum RequiredIntro is export <
	NONE
	NICK
	PREFIX
	EITHER
	BOTH
>;

role Command[Str $command-name, Bool $abbreviate = True] {
	has $.command-name = $command-name;
	has $.abbreviate = $abbreviate;
}

multi trait_mod:<is>(Routine:D $m, :$cmd!) is export {
	if $cmd !~~ Bool {
		my $opts = $cmd.hash;
		$m does Command[
			( $opts<name>    // $m.name    ),
			( $opts<abbreviate> !eqv False ),
		];
	}
	else {
		$m does Command[$m.name];
	}
}

sub abbrev($name) { [\~] $name.comb }

role Net::IRC::CommandHandler {
	has Str $.prefix is rw = '!';
	has RequiredIntro $.required-intro is rw = EITHER;

	has @!cmds       = self.^methods.grep(Command);
	has %cmd-names   = @!cmds.map({ $^n.command-name => $^n });
	has %short-names = {}.push(
		@!cmds.grep(*.abbreviate).map({ abbrev($^n.command-name) X=> $^n }).flat
	);

	method recognized($handler: $ev) {
		return $ev.cache<CommandHandler>{$handler.prefix} //= sub {
			$ev.what ~~ token {
				# Intro
				^
				[ \s* $<nick>=("$ev.state()<nick>") [ <[:,]> | \s ] ]? \s*
				[ $<prefix>=("$handler.prefix()") \s* ]?

				# Actual command (and optional params)
				$<command>=(\w+) [ <?> | \s+ $<params>=(.*) ] #++# <- Fool sublime's perl parser
				$
			} or return False;

			# Let private chat act as specifying the bot's nick
			my $nick = $<nick> || $ev.where eq $ev.state<nick>;

			given $.required-intro {
				when NICK   { return False unless $nick              }
				when PREFIX { return False unless $<prefix>          }
				when EITHER { return False unless $<prefix> || $nick }
				when BOTH   { return False unless $<prefix> && $nick }
			}

			return $/;
		}();
	}

	multi method said ($ev where { $/ := $.recognized($ev) }) {
		self!dispatch($<command>, $ev, $/);
	}

	method !dispatch($name, *@args) {
		given %cmd-names{$name} // %short-names{$name} {
			when Callable   { .(self, |@args) }
			when Positional { warn "Cannot disambiguate '$name'. Possible commands: {$_>>.name.join(', ')}" }
		}
	}

	method usage($ev, $usage) {
		$ev.msg("Usage: $usage");
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4
