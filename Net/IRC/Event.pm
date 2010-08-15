use v6;

class Net::IRC::Event {
	#EVERY event has to have these:
	has $.raw;
	has $.command;
	has $.conn;
	has $.state;
	
	#Most events can have these.
	has $.who;
	has $.what;
	has $.where;

	
	##Utility methods
	method msg($text, $to = $.where) {
		##IRC RFC specifies 510 bytes as the maximum allowed to send per line. 
		#I'm going with 480, as 510 seems to get cut off on some servers.
		my $prepend = "PRIVMSG $to :";
		my $maxlen = 480-$prepend.bytes;
		for $text.split(/\c13?\c10/) -> $line is rw {
			while $line.bytes > $maxlen {
				#Break up the line using a nearby space if possible.
				my $index = $line.rindex(" ", $maxlen) || $maxlen;
				$.conn.sendln($prepend~$line.substr(0, $index));
				$line := $line.substr($index+1); 
			}
			$.conn.sendln($prepend~$line); 
		}
	}
	
	method act($text, $to = $.where) {
		$.conn.sendln("PRIVMSG $to :\c01ACTION $text\c01")
	}
	
	method send_ctcp($text, $to = $.where) {
		$.conn.sendln("NOTICE $to :\c01$text\c01");
	}
}
