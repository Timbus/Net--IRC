use v6;

module Net::IRC::TextUtil;

sub _s($num, $plural = 's', $singular = '') is export {
	$num == 1 ?? $singular !! $plural;
}

sub friendly-duration($seconds) is export {
	my $minute = 60;
	my $hour   = $minute * 60;
	my $day	   = $hour * 24;
	my $week   = $day * 7;

	given $seconds.Int {
		when * < $minute {
			"$_ second{_s($_)}"
		}
		when * < 59.5 * $minute {
			my $minutes = ($_ / $minute).round;
			"$minutes minute{_s($minutes)}"
		}
		when * < 23.5 * $hour {
			my $hours = ($_ / $hour).round;
			"$hours hour{_s($hours)}"
		}
		when * < 6.5 * $day {
			my $days  = ($_ / $day).round;
			"$days day{_s($days)}"
		}
		default {
			 my $weeks = ($_ / $week).round;
			 "$weeks week{_s($weeks)}"
		}
	}
}


# IRC Max message length is 512. 
#-2 for \r\n,
#-65 for max hostname length, and the @! symbols
# = 445 right off the bat.
constant max-length = 445;

# And also if not known, we also take the following:
#-30 for max nickname length (most servers)
#-30 userident
#-32 max channel name
#-10 for command + colon
# = 102 worst case.
constant max-prefix = 102;

sub cut($text, $prefix-length=max-prefix) is export {
	my $maxlen = max-length - $prefix-length;
	return gather for $text.lines -> $line is rw {
		while $line.encode.bytes > $maxlen {
			#Break up the line using a nearby space if possible.
			my $index = $line.rindex(" ", $maxlen) || $maxlen;
			take ($line.substr-rw(0, $index, ''));
		}
		take ($line); 
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4
