#!/usr/bin/env perl6
use v6;
use Net::IRC::Bot;
use Net::IRC::Logger;
use Net::IRC::Modules::ACME;
use Net::IRC::Modules::Autoident;

Net::IRC::Bot.new(
	log-level  => DEBUG,
	logfile    => $*OUT,
	nick       => 'nyhymrg',
	server     => 'irc.freenode.org',
	channels   => <#bottest>,
	modules    => ( 
		Net::IRC::Modules::ACME::Bark::LikeADog.new,
		Net::IRC::Modules::ACME::Bark::LikeATree.new(prefix => '@'),
		Net::IRC::Modules::ACME::Eightball.new, 
		#Net::IRC::Modules::ACME::Unsmith.new 
	),
).run;
