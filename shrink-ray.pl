
use 5.20.1;
use strict;
use warnings;
use File::Find;
use File::Basename;
use File::stat;
use File::Copy;

say "Starting run...";

#TODO: Add more error checking
#TODO: Load values from config file instead of hardcoding
#TODO: Add mechanism for skipping certain files
#TODO: Take video resolution into account when deciding if it is too big or not
#TODO: Add an option to stop after a certain amount of time has elapsed

my $max_rate = 30;
my @directories = (
  '/media/sf_media1/movies_kids/',
  '/media/sf_media1/movies_grown_up/',
);

find(\&wanted,  @directories);

sub wanted
{
  return unless m/\.(mp4|mpg|mkv|wmv)$/;

  my $filename = fileparse($File::Find::name,qr/\.[^.]*/);
  my $sb = stat($File::Find::name);
  my $duration_ms =  `mediainfo --Inform="General;%Duration%" "$_"`;
  chomp($duration_ms);
  my $duration_m = $duration_ms/1000/60;
  my $size_mb = $sb->size/1024/1024;
  my $rate = $size_mb/$duration_m;

  say $filename;
  say "\tDuration: $duration_m Minutes";
  say "\tSize:     $size_mb MB";
  say "\tRate :    $rate MB per Minute";

  if($rate < $max_rate )
  {
    say "\t**** Video is small enough.  Skipping....";
    return;
  }

  print "\tTranscoding ... ";
  my $output =  `HandBrakeCLI -i "$_" -o transcoded.mp4 --preset="High Profile" 2> /dev/null `;
  print " Done.\n";

  if (-e 'transcoded.mp4') 
  {
    move($File::Find::name, $File::Find::name . '.old');
    move('transcoded.mp4',"$filename.mp4");
    unlink($File::Find::name . '.old');
  }
  else
  { 
    say "\t***ERROR*** transcoded.mp4 doesn't exist";
    die;
  }
}

1;

