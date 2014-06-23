use v6;
use Net::IRC::CommandHandler;
use Net::IRC::TextUtil;

#= Save messages to pass on to users when they are active again
class Net::IRC::Modules::Tell does Net::IRC::CommandHandler {
	class Message {
		has $.sender;
		has $.message;
		has $.when;
	}
	has %messages;
	
	#= Use 'tell <nick> <message>' to save a message for delivery when that nick is active again
	method command_tell ( $ev, $match ) {
		my $from = $ev.who;
		if $match<params> ~~ /$<name>=<+ alpha + [ \[..\] \{..\} ]>+ <.punct>? <.ws> $<msg>=[.+]/ {
			if $<name>.lc eq $from.lc|'me' {
				$ev.msg("$from: I think you can tell yourself that!");
				return;
			}
			%messages{$<name>.lc} //= [];
			%messages{$<name>.lc}.push(
				Message.new(sender => $from, when => time, message => ~$<msg>)
			);
			$ev.msg("$from: Noted. I'll pass that on when I see $<name>");
		}
		else {
			self.usage($ev, 'tell <nick> <message>');
		}
	}
	
	multi method said ( $ev where {$ev.who.lc ~~ %messages} ) {
		self!deliver-message($ev)
	}
	
	multi method joined ( $ev ) {#where {$ev.who.lc ~~ %messages} ) {
		say 'okay I joined';
		#self!deliver-message($ev)
	}
	
	multi method nickchange ( $ev where {$ev.what.lc ~~ %messages} ) {
		self!deliver-message($ev)
	}
	
	method !deliver-message( $ev ){
		my $reciever = $ev.who;
		for @(%messages{$reciever.lc}) -> $msg {
			my $elapsed = friendly-duration(time - $msg.when);
			$ev.msg("$reciever: <{$msg.sender}> {$msg.message} ::$elapsed ago");
		}
		%messages{$reciever.lc} = [];
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4

