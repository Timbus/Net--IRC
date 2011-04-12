use v6;
class Tell {
	class Message {
		has $.sender;
		has $.message;
		has $.when;
	}
	has %messages;
	
	multi method said ( $ev where {$ev.what ~~ /^<{$ev.state<nick>}><.punct>?<.ws>'tell'/} ) {
		my $from = $ev.who;
		if $ev.what ~~ /tell <.ws> $<name>=<-space -punct>+ <.punct>? <.ws> $<msg>=[.+]/ {
			if $<name>.lc eq $from.lc|'me' {
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
	
	multi method said ( $ev where {$ev.who.lc ~~ %messages} ) {
		self!deliver-message($ev)
	}
	
	multi method joined ( $ev where {$ev.who.lc ~~ %messages} ) {
		self!deliver-message($ev)
	}
	
	multi method nickchange ( $ev where {$ev.what.lc ~~ %messages} ) {
		self!deliver-message($ev)
	}
	
	method !deliver-message( $ev ){
		my $reciever = $ev.who;
		for @(%messages{$reciever.lc}) -> $msg {
			my $elapsed = self!format-time(time - $msg.when);
			$ev.msg("$reciever: <{$msg.sender}> {$msg.message} ::$elapsed ago");
		}
		%messages{$reciever.lc} = [];
	}
	
	method !format-time($elapsed) {
		given $elapsed { 
			when * < 60 { 
				return "$elapsed second"~($elapsed != 1 ?? 's' !! '');
			}
			when * < 3570 {
				my $mins = ($elapsed / 60).round;
				return "$mins minute"~($mins != 1 ?? 's' !! '');
			}
			when * < 84600 {
				my $hours = ($elapsed / 60 / 60).round;
				return "$hours hour"~($hours != 1 ?? 's' !! '');
			}
			when * < 604800 {
				my $days = ($elapsed / 60 / 60 / 24).round;
				my $hours = ($elapsed % 86400 / 60 / 60).round;
				return 
					"$days day" ~
					($days != 1 ?? 's' !! '') ~ 
						$hours ?? (", $hours hour" ~
						($hours != 1 ?? 's' !! '') ) !! '';
			} 
			dafault {
				my $days = ($elapsed / 60 / 60 / 24).round;
				return "$days day"~($days != 1 ?? 's' !! '');
			}
		}
	}
}
