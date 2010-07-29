use v6;

#use Net::IRC::Bot;
class Net::IRC::Bot {...};

grammar Event {
	rule TOP {
		| ^':'?$<command>=(P[I|O]NG) ':'?$<text>=(.+)?$
		| ^':'?$<command>=(ERROR) ':'?$<text>=(.+)$
		| ^':'?$<from>=<-space>+ $<command>=<-space>+[ <!before ':'>$<param>=<-space>+]*?[ ':'$<text>=(.+)]?<.ws>?$
	}
}#**

class Net::IRC::Dispatcher {
	has $bot;
	has $connection;
	#TODO: has @connections;
	
	method run() {
		$bot.connect();
		loop {
		
			#XXX: Support for timed events?
			
			my $line = $connection.get 
				or fail('Server closed connection')
			
			my $event = Event.parse($line)
				or warn "Could not parse the following IRC event: $line";	
			#---FOR DEBUGGING----
			say ~$event;
			#--------------------
			
			$.dispatch($event);
			
			CATCH {
				#On the event of a dicconnect, we retry (if the bot is told to do so..)
				if $! eq 'Server closed connection' {
					$bot.reconnect;
					next;
				}
				last;
			}
		}
	}
	
	method dispatch(Match $event) {
		#Dispatch to any raw irc_event handlers first
		$bot.*"irc_{ lc $event<command> }"($event);

		given ~$event<command> {
			when "PRIVMSG" {
				my $from = $bot.strip_nick(~$event<from>);
				my $channel = ~$event<param>[0] ~~ /^\#.*/ || $from;
				my $text = ~$event<text>;
				
				#Check to see if its a CTCP request.
				if $text ~~ /^\c01 (.*) \c01$/ {
					$text = ~$0;
					say "Received CTCP $text from $from" ~ ( $channel eq $from ?? '.' !! " (to channel $channel)." );

					if $text ~~ /^ ACTION\s (.*) $/ {
						$bot.*emoted(~$0, ~$from, ~$channel);
					}
					else {
						$text ~~ /^ (.+?) [\s(.*)]? $/;
						if $1 {
							$bot.*"ctcp_{ lc $0 }"(~$1, ~$from, ~$channel);
						}
						else {
							$bot.*"ctcp_{ lc $0 }"(~$from, ~$channel);
						}
					}
				}
				
				else {
					$bot.*said(~$text, ~$from, ~$channel);
				}
			}
	
			when "NOTICE" {
				my $from = $bot.strip_nick(~$event<from>);
				my $channel = ~$event<param>[0] ~~ /^\#.*/ || $from;
				$bot.*noticed(~$event<text>, ~$from, ~$channel);
			}
			
			when "KICK" {
				my $from = $bot.strip_nick(~$event<from>);
				my $channel = ~$event<param>[0];
				my $kicked = ~$event<param>[1];
				$bot.*kicked($kicked, ~$event<text>, $from, $channel);
			}
			
			when "JOIN" {
				my $from = $bot.strip_nick(~$event<from>);
				my $channel = ~$event<text>;
				$bot.*joined($from, $channel);
			}
			
			when "NICK" {
				my $from = $bot.strip_nick(~$event<from>);
				my $to = ~$event<text> // ~$event<param>[0];
				$bot.*nickchange($from, $to);
			}
		
			when "376"|"422" {
				#End of motd / no motd. (Usually) The last thing a server sends the client on connect.
				$bot.*connected;
			}
			
			default {
				$bot.*"{ lc $event<command> }"($event);
			}
		}
		
	}
}
