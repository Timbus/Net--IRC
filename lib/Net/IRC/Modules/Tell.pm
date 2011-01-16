use v6;
class Tell {
	class Message {
		has $.sender;
		has $.message;
		has $.when;
	}
	has %messages;
	
	multi method said ( $ev where {$ev.what ~~ /^<{$ev.state<nick>}><.punct>?<.ws>'tell'/} ) {
		my $from = $ev.who<nick>.lc;
		if $ev.what ~~ /tell <.ws> $<name>=<-space -punct>+ <.punct>? <.ws> $<msg>=[.+]/ {
			if $<name>.lc eq $from|'me' {
				$ev.msg("$from: I think you can tell yourself that!");
				return;
			}
			%messages{$<name>.lc} //= []; #/
			%messages{$<name>.lc}.push(
				Message.new(sender => $from, when => time, message => ~$<msg>)
			);
			$ev.msg("$from: Noted. I'll pass that on when I see $<name>");
		}
	}
	
	#TODO: Put the following methods into a single private method.
	multi method said ( $ev where {$ev.who<nick>.lc ~~ %messages} ) {
		my $reciever = $ev.who<nick>.lc;
		for %messages{$reciever}.values -> $msg {
			#TODO: Make sub to determine a cleaner elapsed time. 
			my $elapsed = $msg.when - time;
			$ev.msg("$reciever: <{$msg.sender}> {$msg.message} ::$elapsed seconds ago");
		}
		%messages{$reciever} = [];
	}
	
	multi method joined ( $ev where {$ev.who<nick>.lc ~~ %messages} ) {
		my $reciever = $ev.who<nick>.lc;
		for %messages{$reciever}.values -> $msg {
			my $elapsed = $msg.when - time;
			$ev.msg("$reciever: <{$msg.sender}> {$msg.message} ::$elapsed seconds ago");
		}
		%messages{$reciever} = [];
	}
	
	multi method nickchange ( $ev where {$ev.what.lc ~~ %messages} ) {
		my $reciever = $ev.what.lc;
		for %messages{$reciever}.values -> $msg {
			my $elapsed = $msg.when - time;
			$ev.msg("$reciever: <{$msg.sender}> {$msg.message} ::$elapsed seconds ago");
		}
		%messages{$reciever} = [];
	}
}
