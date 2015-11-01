use v6;
use Net::IRC::CommandHandler;

#= Provides a generic help system
class Net::IRC::Modules::Help does Net::IRC::CommandHandler {

	#= Use 'help commands' for the command list, 'help <command>' to show help for that command, 'help modules' for the active module list, or 'help <module>' for info on that module
	method help ( $ev, $match ) {
		# Gather info about all modules and all commands
		# XXXX: Cache this?
		my @modules  = $ev.bot.modules;
		my (%modules, %commands);

		for @modules -> $module {
			next if $module.^name eq 'Net::IRC::Handlers::Default';
			my $module-name	    = $module.^name.subst(/^'Net::IRC::Modules::'/, {''});
			my @command-methods = $module.^methods.grep(Command);

			%commands = {}.push: @command-methods.map({$^method.command-name => $^method});

			%modules{$module-name} := {
				module	 => $module,
				methods	 => %commands.keys,
				commands => %commands.values,
			};
		}

		# Display help info for each subject queried
		my @subjects = ($match<params> // 'help').split(/\s+/);
		for @subjects -> $subject {
			if %modules{$subject} -> $info {
				my @commands = $info<commands>.sort.uniq;
				my $commands = @commands.join(', ') || 'none';
				$ev.msg("Module $subject: { $info<module>.WHY || 'No help text found' } [commands: $commands]");
			}

			if %commands{$subject} -> $methods {
				# XXXX: What about prefixes?
				for $methods.list -> $method {
					$ev.msg("Command $subject: { $method.WHY || 'No help text found' }");
				}
			}

			if $subject eq 'modules' {
				$ev.msg("Active modules: { %modules.keys.sort.join(', ') }");
			}

			if $subject eq 'commands' {
				# XXXX: What about prefixes?
				$ev.msg("Known commands: { %commands.keys.sort.join(', ') }");
			}
		}
	}
}

# vim: ft=perl6 tabstop=4 shiftwidth=4
