use v6;

class Net::IRC::DefaultHandlers {
    ##Some default handler methods

	#Error handler
	multi method irc_error($ev) {
		die $ev.raw;
		#Or maybe die ~$ev.raw?
	}
	#Ping handler
	multi method irc_ping($ev) {
		say $ev.raw;
		$ev.conn.sendln("PONG :{ $ev.what }");
	}

	#XXX: Fix when 'state' works again
	has $nickattempts = 0; 
	#443: ERR_NICKNAMEINUSE
	multi method irc_433($ev) {
		#If this event occurs while we try to login, try to change nicks. Otherwise ignore it.
		if not $ev.state<loggedin> {
			#Is it time to give up?
			if $ev.state<altnicks> > $nickattempts {
				die('Cannot connect to server. All supplied nicknames are taken');
			}
			else {
				$ev.conn.sendln( "NICK {$ev.state<altnicks>[$nickattempts++]}" );
			}
		}
	}
	#001: Welcome message sent after successful NICK/USER
	#This event sets $loggedin to true, turning off the above nick handler
	multi method irc_001($ev) {
		$ev.state<loggedin> = True;
	}

	#Autojoin method. Handy.
	multi method connected($ev) {
		$ev.conn.sendln("JOIN $_") for $ev.state<autojoin>;
	}


	multi method irc_join($ev) {
		my $joiner = $ev.who<nick>;
		#Did someone join a channel we are in?
		if $joiner ne $ev.state<nick> {
			my $ulist = $ev.state{'channels'}{ $ev.where };
			$ulist.push($joiner => 1) unless $ulist{$joiner};
		}

		#Else did we ourselves join somewhere?
		#Our own state will (SHOULD) be updated in a few milliseconds (irc_353)
	}

	#XXX: Should we also track who has ops/voice/etc??
	#353: User list for newly joined channel
	multi method irc_353($ev) {
		$ev.state{'channels'}{ ~$ev.raw<param>[2] } =
			%( $ev.what.comb(/<-space - [\+\%\@\&\~]>+/) >>=>>> 1 );
	}

	multi method irc_kick($ev) {
		my $kicked = ~$ev.raw<param>[1];
		if $kicked eq $ev.state<nick> {
			$ev.state<channels>.delete( ~$ev.where );
		}
		else {
			$ev.state<channels>{ ~$ev.where }.delete($kicked);
		}
	}

	multi method irc_part($ev) {
		my $parted = $ev.who<nick>;
		if $parted eq $ev.state<nick> {
			$ev.state<channels>.delete( ~$ev.where );
		}
		else {
			$ev.state<channels>{ ~$ev.where }.delete($parted);
		}
	}

	multi method irc_nick($ev) {
		my $oldnick = $ev.who<nick>;
		if $oldnick eq $ev.state<nick> {
			$ev.state<nick> = ~$ev.what;
		}
		else {
			for $ev.state<channels>.values -> $users {
				$users.delete($oldnick) && $users<$nick> = 1 if $users<$oldnick>;
			}
		} 
	}

	proto method ctcp_version($ev) {
		$ev.send_ctcp("VERSION Perl6bot 0.001a Probably *nix");
	}
}

