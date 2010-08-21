use v6;
module Tell;


class Tell {
	class Message {
		has $.who;
		has $.when;
		has $.what;
	}
	has %messages;
	
	multi method said ( $msg where /^{$.nick}<.punct>? 'tell'/, $from, $channel ) {
		if $msg ~~ /tell <.ws> $<name>=<-space>+? <[:.,]>?<.ws> $<msg>=[.+]/ {
			if ~$<name> eq $from {
				$.say("$from: I think you can tell yourself that!", $channel);
				return;
			}
			%messages{~$<name>} //= []; #/
			%messages{~$<name>}.push(
				Message.new(who => $from, when => time, what => ~$<msg>)
			);
			$.say("$from: Noted. I'll pass that on when I see $<name>", $channel);
		}
	}
	
	multi method said ( $msg, $from where %messages, $channel ) {
		for %messages{~$from}.values -> $msg {
			#TODO: Make sub to determine a cleaner elapsed time. 
			#Haven't done it because I dunno how to elegantly hide subs in a role..
			my $elapsed = $msg.when - time;
			$.say("$from: <{$msg.who}> {$msg.what} ::$elapsed seconds ago", $channel);
		}
		%messages{~$from} = [];
	}
	
	multi method joined ( $who where %messages, $channel ) {
		
	}

}
