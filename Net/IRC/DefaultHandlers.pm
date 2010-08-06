use v6;

class Net::IRC::DefaultHandlers {
    ##Some default handler methods
	
	#Error handler
	multi sub method irc_error($event) {
		say $event;
		$.disconnect;
		$.connect if $autoreconnect;
	}
	#Ping handler
	multi method irc_ping($event) {
		$conn.sendln("PONG :{ $event<text> }");
	}
	
	#443: ERR_NICKNAMEINUSE
	multi method irc_433($event) {
		#If this event occurs while we try to login, try to change nicks. Otherwise ignore it.
		unless $loggedin {
			#Is it time to give up?
			if @altnicks > $nickattempts {
				$conn.disconnect();
				fail('Cannot connect to server. All supplied nicknames are taken');
			}
			else {
				$conn.sendln( "NICK {@altnicks[$nickattempts++]}" );
			}
		}
	}
	#001: Welcome message sent after successful NICK/USER
	#This event sets $loggedin to true, turning off the above nick handler
	multi method irc_001($event) {
		$loggedin = True;
	}
	
	#Autojoin method. Handy.
	multi method connected() {
		$conn.sendln("JOIN $_") for @autojoin;
	}
	
	
	multi method irc_join($event) {
		my $joiner = $.strip_nick(~$event<from>);
		#Did someone join a channel we are in?
		if $joiner ne $nick {
			%channels{ ~$event<text> } = { $joiner => 1 };
		}
		
		#Else did we ourselves join somewhere?
		#Our own state will (SHOULD) be updated in a few milliseconds (irc_353)
	}
	
	#353: User list for newly joined channel
	multi method irc_353($event) {
		%channels{ ~$event<param>[2] } = 
			$event<text>.split(' ').grep(*).map({ $^a ~~ s/^ <[\+\%\@\&\~]>//; });
	}
	
	multi method irc_kick($event) {
		my $kicked = ~$event<param>[1];
		if $kicked eq $nick {
			%channels.delete( ~$event<param>[0] );
		}
		else {
			my $users = %channels{ ~$event<param>[0] };
			$users.delete($kicked);
		}
	}
	
	multi method irc_part($event) {
		my $parted = $.strip_nick(~$event<from>);
		if $parted eq $nick {
			%channels.delete( ~$event<param>[0] );
		}
		else {
			my $users = %channels{ ~$event<param>[0] };
			$users.delete($parted);
		}
	}
	
	multi method irc_nick($event) {
		my $oldnick = $.strip_nick(~$event<from>);
		if $oldnick eq $nick {
			$nick = ~$event<text>;
		}
		else {
			for %channels.values -> $users {
				$users.delete($oldnick) && $users<$nick> = 1 if $users<$oldnick>;
			}
		}
	}
	
	multi method ctcp_version($event) {
		$.send_ctcp("VERSION Perl6bot 0.001a Probably *nix", $from);
	}
}
