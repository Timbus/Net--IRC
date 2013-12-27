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

# vim: ft=perl6 tabstop=4 shiftwidth=4
