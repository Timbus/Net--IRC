use v6;
class Tell {
	class Message {
		has $.sender;
		has $.message;
		has $.when;
	}
	has %messages;
	
	multi method said ( $ev where {$ev.what ~~ /^{$ev.state<nick>}<.punct>? 'tell'/} ) {
		if $ev.what ~~ /tell <.ws> $<name>=<-space>+? <[:.,]>?<.ws> $<msg>=[.+]/ {
			if ~$<name> eq $ev.who {
				$ev.say("{$ev.who}: I think you can tell yourself that!");
				return;
			}
			%messages{~$<name>} //= []; #/
			%messages{~$<name>}.push(
				Message.new(sender => $ev.who, when => time(), message => ~$<msg>)
			);
			$ev.say("{$ev.who}: Noted. I'll pass that on when I see $<name>");
		}
	}
	
	multi method said ( $ev where {$ev.who ~~ %messages} ) {
		for %messages{~$ev.who}.values -> $msg {
			#TODO: Make sub to determine a cleaner elapsed time. 
			#Haven't done it because I dunno how to elegantly hide subs in a role..
			my $elapsed = $msg.when - time;
			$ev.say("{$ev.who}: <{$msg.sender}> {$msg.message} ::$elapsed seconds ago");
		}
		%messages{~$ev.who} = [];
	}
	
	multi method joined ( $who where %messages, $channel ) {
		
	}

}
