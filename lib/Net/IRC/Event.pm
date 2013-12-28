use v6;

class Net::IRC::Event {

	#EVERY event has to have these:
	has $.raw is rw;
	has $.command is rw;
	has $.conn is rw;
	has $.state is rw;
	has $.bot is rw;
	
	#Most events can have these.
	has $.who is rw;
	has $.what is rw;
	has $.where is rw;

	# Per-event cache to prevent many modules from repeating the same work
	has %.cache;

	
	##Utility methods
	method msg($text, $to = self!default-to) {
		##IRC RFC specifies 510 bytes as the maximum allowed to send per line. 
		#I'm going with 480, as 510 seems to get cut off on some servers.

		my $prepend = "PRIVMSG $to :";
		my $maxlen = 480-$prepend.encode.bytes;
		for $text.split(/\c13?\c10/) -> $line is rw {
			while $line.encode.bytes > $maxlen {
				#Break up the line using a nearby space if possible.
				my $index = $line.rindex(" ", $maxlen) || $maxlen;
				$.conn.sendln($prepend~$line.substr(0, $index));
				$line = $line.substr($index+1); 
			}
			$.conn.sendln($prepend~$line); 
		}
	}
	
	method act($text, $to = self!default-to) {
		$.conn.sendln("PRIVMSG $to :\c01ACTION $text\c01")
	}
	
	method send_ctcp($text, $to = self!default-to) {
		$.conn.sendln("NOTICE $to :\c01$text\c01");
	}

	method !default-to() {
		$.where eq $.state<nick> ?? $.who !! $.where;
	}
	
	method Str {
		$.what ?? ~$.what !! $.raw;
	}

	multi method gist(Net::IRC::Event:D:) {
		join "\n",
			"Event($.command)",
			("    where: $.where" if $.where),
			("     what: $.what"  if $.what),
			("      who: $.who"   if $.who),
			 "      raw: $.raw",
			;
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4
