# Originally designed to trigger hue lights on/off
#when arriving and leaving my apartment (the geofencing sucks)
#Sends an email to trigger@recipe.ifttt.com


#works with strawberry
#use at your own risk -- should you attached-detach
#from your network too much you'll have a lot of spam on your hands

#use gmail...it's easier. Also just make a junk account so you can 
#leave your passwd in here...until version two!!

use strict;
use warnings;
use Win32;
use Win32::Daemon;
use Net::Ping;
use Email::Send;
use Email::Send::Gmail;
use Email::Simple::Creator;
		my $p = Net::Ping->new();
			my $status;
			my $host="<CHANGEME>";
			$p->ping($host) ? $status=1 : $status=0;
			$p->close(); 
										 
my $email = Email::Simple->create(header => [From=> '<CHANGEME>@gmail.com',To => 'trigger@recipe.ifttt.com',Subject => '#found',],body => 'Home',);
my $email2 = Email::Simple->create(header => [From=> '<CHANGEME>@gmail.com',To => 'trigger@recipe.ifttt.com',Subject => '#lost',],body => 'Away',);										  

  my $sender = Email::Send->new(
	  {   mailer      => 'Gmail',
		  mailer_args => [
			  username => '<CHANGEME>@gmail.com',
			  password => '<CHANGEME>',
		  ]
	  }
  ); 
main();
use constant SERVICE_NAME => 'ippp';
use constant SERVICE_DESC => 'holy shit perl in a service!';
sub main
{
   my $opt = shift (@ARGV) || "";

   if ($opt =~ /^(-i|--install)$/i)
   {
      install_service(SERVICE_NAME, SERVICE_DESC);
   } 
   elsif ($opt =~ /^(-r|--remove)$/i)
   {
      remove_service(SERVICE_NAME);
   }
   elsif ($opt =~ /^(--run)$/i)
   {
      # Redirect STDOUT and STDERR to a log file
      my ($cwd,$bn,$ext) = 
      ( Win32::GetFullPathName($0) =~ /^(.*\\)(.*)\.(.*)$/ ) [0..2] ;
      my $log = $cwd . $bn . ".log";  
      open(STDOUT, ">> $log") or die "Couldn't open $log for appending: $!\n";
      open(STDERR, ">&STDOUT");
      $|=1;
      Win32::Daemon::RegisterCallbacks( {
            start       =>  \&Callback_Start,
            running     =>  \&Callback_Running,
            stop        =>  \&Callback_Stop,
            pause       =>  \&Callback_Pause,
            continue    =>  \&Callback_Continue,
         } );
      my %Context = (
         last_state => SERVICE_STOPPED,
         start_time => time(),
      );
      Win32::Daemon::StartService( \%Context, 10000 );
      close STDERR; close STDOUT;
   }
   else 
   {
      print "No valid options passed - nothing done\n";
	  print "Usage: ippp.pl (--install | --remove)\n"
	  print "installs as a windows service that starts at boot.\n"
   }
}
sub Callback_Running
{     
   my( $Event, $Context ) = @_;
   if( SERVICE_RUNNING == Win32::Daemon::State() )
   {

					print "Initial status = $status\n";
					my $p = Net::Ping->new();
					if($p->ping($host) && $status == 0) {
					$sender->send($email);
					$status = 1;
					print "Sent email\n";
					}elsif(!($p->ping($host)) && $status == 1) {
					$sender->send($email2);
					$status = 0;
					print "Sent email2\n";
					}else {
					print "Did nothing\n";
					}
$p->close();
   }
}    
sub Callback_Start
{
   my( $Event, $Context ) = @_;
   # Initialization 
   print "Starting...\n";
   $Context->{last_state} = SERVICE_RUNNING;
   Win32::Daemon::State( SERVICE_RUNNING );
}
sub Callback_Pause
{
   my( $Event, $Context ) = @_;
   print "Pausing...\n";
   $Context->{last_state} = SERVICE_PAUSED;
   Win32::Daemon::State( SERVICE_PAUSED );
}
sub Callback_Continue
{
   my( $Event, $Context ) = @_;
   print "Continuing...\n";
   $Context->{last_state} = SERVICE_RUNNING;
   Win32::Daemon::State( SERVICE_RUNNING );
}
sub Callback_Stop
{
   my( $Event, $Context ) = @_;
   print "Stopping...\n";
   $Context->{last_state} = SERVICE_STOPPED;
   Win32::Daemon::State( SERVICE_STOPPED );
   Win32::Daemon::StopService();
}
sub install_service
{
   my ($srv_name, $srv_desc) = @_;
   my ($path, $parameters);
   my $fn = Win32::GetFullPathName($0);
   my ($cwd,$bn,$ext) = ( $fn =~ /^(.*\\)(.*)\.(.*)$/ ) [0..2] ;
   if ($ext eq "pl")
   {
      $path = "\"$^X\"";
      my $inc = ($cwd =~ /^(.*?)[\\]?$/) [0];
      $parameters = "-I " . "\"$inc\"" . " \"$fn\" --run";
   }
   elsif ($ext eq "exe")
   {
      $path = "\"$fn\"";
      $parameters = "";
   }
   else 
   {
      die "Can not install service for $fn, file extension $ext not supported\n";
   }
   my %srv_config = (
      name         => $srv_name,
      display      => $srv_name,
      path         => $path,
      description  => $srv_desc,
      parameters   => $parameters,
      service_type => SERVICE_WIN32_OWN_PROCESS,
      start_type   => SERVICE_AUTO_START,
   );

   if( Win32::Daemon::CreateService( \%srv_config ) )
   {
      print "Service installed successfully\n";
	  print "Sleeping for 10 seconds then starting your service.\n";
	  sleep(10);
	  
	  print "Open an administrator CMD and run: 'sc start ippp' to get started.\n";
	  print "Done.\n";
   }
   else 
   {
      print "Failed to install service\n";
   }
}

sub remove_service
{
   my ($srv_name, $hostname) = @_;
   $hostname ||= Win32::NodeName(); 
   if ( Win32::Daemon::DeleteService ( $srv_name ) ) 
   {
      print "Service uninstalled successfully\n";
   }
   else 
   {
      print "Failed to uninstall service\n";
   }
}