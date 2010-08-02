use Net::IRC::Connection;

class User {
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

multi infix:<=> (User $u is rw, Str $s) {
	$u .= new($s);	
}

class Net::IRC::Bot {
	#has Net::IRC::Handler $manager;
	#has Net::IRC::Connection $conn handles <get sendln>;
	
	has $manager;
	has $conn handles <get sendln>;
	
	#Set some sensible defaults for the bot.
	has $nick = "Rakudobot";
	has @altnicks = $nick «~« ("_","__",^10);
	has $username = "Clunky";
	has $realname = '$@%# yeah, perl!';
	
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
	
	method create(){
		$manager = Net::IRC::Dispatcher.new(bot => self, connection => Net::IRC::Connection.new);
		$.connect;
		$manager.run;
	}
	
	method connect(){
		#Establish connection to server
		say "Connecting to $server on port $port";
		$conn.open($server, $port);

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
	}
	
	method disconnect($quitmsg = "Leaving"){
		if $connected {		
			$conn.sendln("QUIT :$quitmsg");
			$conn.close;
		}
		$.resetstate;
	}
	
	##Utility methods
	method msg($text, $to) {
		##IRC RFC specifies 510 bytes as the maximum allowed to send per line. 
		#I'm going with 480, as 510 seems to get cut off on some servers.
		my $prepend = "PRIVMSG $to :";
		my $maxlen = 480-$prepend.bytes;
		for $text.split(/\c13?\c10/) -> $line is rw {
			while $line.bytes > $maxlen {
				#Break up the line using a nearby space if possible.
				my $index = $line.rindex(" ", $maxlen) || $maxlen;
				$conn.sendln($prepend~$line.substr(0, $index));
				$line .= substr($index+1); 
			}
			$conn.sendln($prepend~$line); 
		}
	}
	
	method reply($text) {
		$.msg($text, $.channel);
	}
	
	method send_ctcp($text, $to) {
		$conn.sendln("NOTICE $to :\c01$text\c01");
	}
	
	method strip_nick($fullnick){
		~$fullnick ~~ /^(<-[\!]>+)'!'/ ?? ~$0 !! ~$fullnick;
	}
	
	##Some default handler methods
	
	#Error handler
	multi method irc_error($event) {
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
	
	multi method ctcp_version($from, $channel) {
		$.send_ctcp("VERSION Perl6bot 0.001a Probably *nix", $from);
	}
	
	method run() {
		$.connect();
		loop {
		
			#XXX: Support for timed events?
			
			my $line = $connection.get 
				or $.reconnect and next
				or last;
			
			my $event = IRCEvent.parse($line)
				or warn "Could not parse the following IRC event: $line";	
			#---FOR DEBUGGING----
			say ~$event;
			#--------------------
			
			$.dispatch($event);
			
			CATCH {
				#On the event of a dicconnect, we retry (if the bot is told to do so..)
				if $! eq 'Server closed connection' {
					$.reconnect;
					next;
				}
				last;
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
					say "Received CTCP $text from $from" ~ ( $channel eq $from ?? '.' !! " (to channel $channel)." );

					if $text ~~ /^ ACTION\s (.*) $/ {
						$.*emoted(~$0, ~$from, ~$channel);
					}
					else {
						$text ~~ /^ (.+?) [\s(.*)]? $/;
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

grammar IRCEvent {
	rule TOP {
		| ^':'?$<command>=(P[I|O]NG) ':'?$<text>=(.+)?$
		| ^':'?$<command>=(ERROR) ':'?$<text>=(.+)$
		| ^':'?$<from>=<-space>+ $<command>=<-space>+[ <!before ':'>$<param>=<-space>+]*?[ ':'$<text>=(.+)]?<.ws>?$
	}
}#**
