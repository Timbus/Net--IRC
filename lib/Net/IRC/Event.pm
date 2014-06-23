use v6;
use Net::IRC::TextUtil;
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
		my $prepend = "PRIVMSG $to :";
		my $prepend-length = 
			$prepend.encode.bytes + 
			$.state<nick>.encode.bytes + 
			$.state<ident>.encode.bytes;
		$.conn.sendln($prepend~$_) for cut($text, $prepend-length);
	}

	method notice($text, $to = self!default-to) {
		my $prepend = "NOTICE $to :";
		my $prepend-length = 
			$prepend.encode.bytes + 
			$.state<nick>.encode.bytes + 
			$.state<ident>.encode.bytes;
		$.conn.sendln($prepend~$_) for cut($text, $prepend-length);
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
