use v6;
use Net::IRC::Connection;

class User is Cool {
	has $.fullnick;
	has $.nick;
	has $.host;
	has $.ident;

	multi method new ($s) {
		~$s ~~ /^$<nick>=(.+?)\!$<ident>=(.+?)\@$<host>=(.+)$/
			or fail('Type check failed for assignment');

		return $.bless(
			*,
			fullnick => ~$s,
			nick => ~$<nick>,
			host => ~$<host>,
			ident => ~$<ident>,
		);
	}

	multi method Str is export {
		return $.nick;
	}

	multi method match is export ($topic) {
		return ($.nick ~~ $topic);
	}
}

our multi infix:<=> (User $u is rw, Str $s) is export {
	$u .= new($s);
}

class Net::IRC::Bot {
	has Net::IRC::Connection $conn;

	#Set some sensible defaults for the bot.
	has $nick = "Rakudobot";
	has @altnicks = $nick «~« ("_","__",^10);
	has $username = "Clunky";
	has $realname = '$@%# yeah, perl 6!';

	has $server = "irc.perl.org";
	has $port = 6667;
	has $password;
	has @autojoin;

	#Options
	has $autoreconnect = False;
	has $throttle = False;

	#State variables.
	has %channels;

	has $loggedin = False;
	has $connected = False;
	has $nickattempts = 0;

	method true {
		$connected;
	}

	method resetstate() {
		%channels     = ();
		$loggedin     = False;
		$connected    = False;
		$nickattempts = 0;
	}

	method connect(){
		#Establish connection to server
		say "Connecting to $server on port $port";
		my $r = $conn.open($server, $port) 
			or die $r;

		#Send PASS if needed
		$conn.sendln("PASS $password") if $password;

		#Send NICK & USER.
		#If the nick collides, we'll resend a new one when we recieve the error later.
		#USER Parameters: 	<username> <hostname> <servername> <realname>
		$conn.sendln("NICK $nick");
		$conn.sendln("USER $username abc.xyz.net $server :$realname");

		$connected = True;
	}

	method reconnect(){
		return False unless $autoreconnect;
		
		my $failcount = 0;
		while ($failcount < 5){
			$.disconnect;
			$.connect;
			
			return True;
		
			CATCH { ++$failcount }
		}
		return False;
	}

	method disconnect($quitmsg = "Leaving"){
		if $connected {		
			$conn.sendln("QUIT :$quitmsg");
			$conn.close;
		}
		$.resetstate;
	}

	grammar RawEvent {
		rule TOP {
			| ^':'?$<command>=(P[I|O]NG) ':'?$<text>=(.+)?$
			| ^':'?$<command>=(ERROR) ':'?$<text>=(.+)$
			| ^':'?$<from>=<-space>+ $<command>=<-space>+[ <!before ':'>$<param>=<-space>+]*?[ ':'$<text>=(.+)]?<.ws>?$
		}
	} #?

	method run() {
		loop {
			#XXX: Support for timed events?
			my $line = $connection.get
				or die "Connection error.";
			
			my $event = RawEvent.parse($line)
				or warn "Could not parse the following IRC event: $line" and next;
			#---FOR DEBUGGING----
			say ~$event;
			#--------------------
			
			$.dispatch($event);
			
			CATCH {
				my $failcount = 0;
				while ($failcount < 5){
					$.disconnect;
					$.connect;
					CATCH { ++$failcount }
				}
			}
		}
	}
	
	method dispatch(Match $event) {
		#Dispatch to any raw irc_event handlers first
		@modules>>.*"irc_{ lc $event<command> }"($event);

		given ~$event<command> {
			when "PRIVMSG" {
				my $from = $.strip_nick(~$event<from>);
				my $channel = ~$event<param>[0] ~~ /^\#.*/ || $from;
				my $text = ~$event<text>;
				
				#Check to see if its a CTCP request.
				if $text ~~ /^\c01 (.*) \c01$/ {
					$text = ~$0;
					say "Received CTCP $text from $from" ~
						( $channel eq $from ?? '.' !! " (to channel $channel)." ); #?

					if $text ~~ /^ ACTION <.ws> (.*) $/ {
						$.*emoted(~$0, ~$from, ~$channel);
					}
					else {
						$text ~~ /^ (.+?) [<.ws>(.*)]? $/;
						if $1 {
							@modules>>.*"ctcp_{ lc $0 }"(~$1, ~$from, ~$channel);
						}
						else {
							@modules>>.*"ctcp_{ lc $0 }"(~$from, ~$channel);
						}
					}
				}

				else {
					@modules>>.*said(~$text, ~$from, ~$channel);
				}
			}

			when "NOTICE" {
				my $from = $.strip_nick(~$event<from>);
				my $channel = ~$event<param>[0] ~~ /^\#.*/ || $from;
				@modules>>.*noticed(~$event<text>, ~$from, ~$channel);
			}
			
			when "KICK" {
				my $from = $.strip_nick(~$event<from>);
				my $channel = ~$event<param>[0];
				my $kicked = ~$event<param>[1];
				@modules>>.*kicked($kicked, ~$event<text>, $from, $channel);
			}
			
			when "JOIN" {
				my $from = $.strip_nick(~$event<from>);
				my $channel = ~$event<text>;
				@modules>>.*joined($from, $channel);
			}
			
			when "NICK" {
				my $from = $.strip_nick(~$event<from>);
				my $to = ~$event<text> // ~$event<param>[0];
				@modules>>.*nickchange($from, $to);
			}
		
			when "376"|"422" {
				#End of motd / no motd. (Usually) The last thing a server sends the client on connect.
				@modules>>.*connected;
			}
			
			default {
				@modules>>.*"{ lc $event<command> }"($event);
			}
		}
	}
}


