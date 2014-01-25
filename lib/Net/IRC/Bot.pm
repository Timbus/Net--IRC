use v6;

use Net::IRC::Logger;
use Net::IRC::SocketConnection;
use Net::IRC::Handlers::Default;
use Net::IRC::Parser;
use Net::IRC::Event;

class Net::IRC::Bot {
	#Connection management
	has $.conn is rw;
	has $!done;

	#Logging
	has $.log-level = INFO;
	has $.logfile   = $*OUT;
	has $.log       = $*LOG;

	#Set some sensible defaults for the bot.
	#These are not stored as state, they are just used for the bot's "start state"
	#Changing things like $nick and @channels are tracked in %.state
	has $.nick     = "Rakudobot";
	has @.altnicks = $!nick X~ ("_","__",^10);
	has $.username = "Clunky";
	has $.realname = '$@%# yeah, perl 6!';

	has $.server   = "irc.perl.org";
	has $.port     = 6667;
	has $.password;

	has @.channels = [];

	#Most important part of the bot.
	has @.modules;

	#State variables.
	#TODO: Make this an object for cleaner syntax.
	has %.state is rw;

	method new(|) {
		my $obj = callsame();
		$obj.modules.push(Net::IRC::Handlers::Default.new);
		$obj
	}

	method !resetstate() {
		%.state = (
			nick         => $.nick,
			altnicks     => @.altnicks,
			autojoin     => @.channels,
			channels     => %(),
			loggedin     => False,
			connected    => False,
		)
	}

	method !connect(){
		#Establish connection to server
		self!resetstate;
		$.log.info: "Connecting to $.server:$.port";
		$.conn = Net::IRC::SocketConnection.new(
			host => $.server, port => $.port,
			input-line-separator => "\c13\c10");

		#Listen for lines from socket
		$.conn.get.tap: { self!process-line($_) };

		#Notice when socket closes
		$.conn.recv.tap: {;}, done => { $!done = True };

		#Send PASS if needed
		$.conn.sendln("PASS $.password", scrubbed => 'PASS ...')
			if $.password;

		#Send NICK & USER.
		#If the nick collides, we'll resend a new one when we recieve the error later.
		#USER Parameters: 	<username> <hostname> <servername> <realname>
		$.conn.sendln("NICK $.nick");
		$.conn.sendln("USER $.username abc.xyz.net $.server :$.realname");
		%.state<connected> = True;
	}

	method !disconnect($quitmsg = "Leaving"){
		if %.state<connected> {
			$.conn.sendln("QUIT :$quitmsg");
			$.conn.close;
		}
	}


	method run() {
		$!log = Net::IRC::Logger.new($.logfile, :min-level($.log-level))
			if !$.log && $.logfile;

		self!disconnect;
		self!connect;
		sleep .1 while !$!done;

		self!disconnect;
		$.log.close;
		sleep .1 while $*SCHEDULER.loads[0];
	}

	method !process-line($line) {
		start {
			$.log.debug: "<-- $line";
			if Net::IRC::Parser::RawEvent.parse($line) -> $raw {
				self!dispatch($raw);
			}
			else {
				$.log.error("Could not parse the following IRC event: $line");
			}
		}
	}

	method !dispatch($raw) {
		#Make an event object and fill it as much as we can.
		#XXX: Should I just use a single cached Event to save memory?
		my $who = ($raw<user> || $raw<server> || "");
		$who does role { method Str { (self<nick> // self<host> ).Str } }

		#XXX Stupid workaround.
		my $l = $raw<params>.elems;

		my $event = Net::IRC::Event.new(
			:raw($raw),
			:command(~$raw<command>),
			:conn($.conn),
			:state(%.state),
			:log($.log),
			:bot(self),
			:who($who),
			:where(~$raw<params>[0]),
			:what(~$raw<params>[$l ?? $l-1 !! 0]),
		);


		# Dispatch to the raw event handlers.
		@.modules>>.*"irc_{ lc $event.command }"($event);
		given uc $event.command {
			when "PRIVMSG" {
				#Check to see if its a CTCP request.
				if $event.what ~~ /^\c01 (.*) \c01$/ {
					my $text = ~$0;
					$.log.debug: "Received CTCP $text from {$event.who}" ~
						( $event.where eq $event.who ?? '.' !! " (to channel {$event.where}).");

					$text ~~ /^ (.+?) [<.ws> (.*)]? $/;
					$event.what = $1 && ~$1;
					self.do_dispatch("ctcp_{ lc $0 }", $event);
					#If its a CTCP ACTION then we also call 'emoted'
					self.do_dispatch("emoted", $event) if uc $0 eq 'ACTION';
				}
				else {
					self.do_dispatch("said", $event);
				}
			}

			when "NOTICE" {
				self.do_dispatch("noticed", $event);
			}

			when "KICK" {
				$event.what = $raw<params>[1];
				self.do_dispatch("kicked", $event);
			}

			when "JOIN" {
				self.do_dispatch("joined", $event);
			}

			when "NICK" {
				self.do_dispatch("nickchange", $event);
			}

			when "376"|"422" {
				#End of motd / no motd. (Usually) The last thing a server sends the client on connect.
				self.do_dispatch("connected", $event);
			}
		}
	}

	method do_dispatch($method, $event) {
		$.log.debug: "Dispatching $method event: $event";
		for @.modules -> $mod {
			if $mod.^find_method($method) -> $multi {
				$multi.cando(Capture.new(list => [$mod, $event]))>>.($mod, $event);
			}
		}
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4

