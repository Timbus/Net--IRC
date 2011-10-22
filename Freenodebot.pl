#!/usr/bin/env perl6
use v6;
use Net::IRC::Bot;
use Net::IRC::Modules::ACME;
use Net::IRC::Modules::Autoident;

Net::IRC::Bot.new(
	nick       => 'Unicron',
	server     => 'irc.freenode.org',
	channels   => <#bottest>,
	modules    => ( 
		Net::IRC::Modules::ACME::Eightball.new, 
		Net::IRC::Modules::ACME::Unsmith.new 
	),
).run;
