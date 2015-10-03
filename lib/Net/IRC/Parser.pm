use v6;

unit module Net::IRC::Parser;
grammar RawEvent {
	token TOP {
		^
		[':' [<user>|<server=host>] <.space> || <?>]
		<command>
		[ <.space>+ [':'$<params>=(.*)$ || $<params>=<-space>+] ]*
		$
	}

	token user {
		$<nick>=<-[:!]>+ '!' $<ident>=<-[@]>+ '@' <host>
	}

	token host {
		#[ <-space - [. $ @ !]>+ ] ** '.'

		#Due to some IRC servers/services allowing anything as a host format,
		#I've decided to define a 'host' as 'anything but a space'. Bah.
		<-space>+
	}

	token command {
		<.alpha>+ | \d\d\d
	}

	token params {
		[ ':'.*$ | <-space>+ ]
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4

