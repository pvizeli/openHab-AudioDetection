use strict;
use v5.10;

use Getopt::Long;
use Proc::Daemon;

###
# Static object
###
my $VERSION = "0.1";
my $daemon  = Proc::Daemon->new();

###
# audioDetection Options
###
my $openHabUrl;
my $openHabItem;
my $ipCamUrl;
my $intPort         = "9554";
my $iceCastUrl;
my $iceCastLegacy   = "";
my $highpass        = "300";
my $lowpass         = "2500";
my $silenceDb       = "-30";
my $silenceSec      = "20";
my $sampleRate      = "16000";
my $pidFile         = "/tmp/audioDetection.pid";
my $daemonStart     = "";
my $daemonStop      = "";

GetOptions(
    "openHabUrl:s"      => \$openHabUrl,
    "openHabItem:s"     => \$openHabItem,
    "ipCamUrl:s"        => \$ipCamUrl,
    "intPort=i"         => \$intPort,
    "iceCastUrl:s"      => \$iceCastUrl,
    "iceCastLegacy"     => \$iceCastLegacy,
    "highpass=i"        => \$highpass,
    "lowpass=i"         => \$lowpass,
    "silenceDb=i"       => \$silenceDb,
    "silenceSec=i"      => \$silenceSec,
    "sampleRate=i"      => \$sampleRate,
    "pidFile=s"         => \$pidFile,
    "start"             => \$daemonStart,
    "stop"              => \$daemonStop,
    "version"           => sub { 
                            say("openHab-AudioDetection $VERSION");
                            exit(0);
                        },
    "help"              => sub { 
                            say("http://github.com/pvizeli/openHab-AudioDetection"); 
                            exit(0);
                        }
) or die("Command line error!");

###
# Deamon controll things
###

# stop daemon
if ($daemonStop) {
    
    # state of daemon
    my $pid = $daemon->Status($pidFile);

    # daemon is running
    if ($pid) {
        $daemon->Kill_Daemon($pid, 'INT');    
    }

    # end program
    exit(0);
}
# start daemon
elsif ($daemonStart) {
    # params okay?
    if (!$openHabUrl or !$openHabItem or !$ipCamUrl) {
        die("Command line error for start a daemon!");
    }

    # start daemon
    my $pid = $daemon->Init({
        pid_file    => $pidFile
    });

    # end program
    if ($pid) {
        exit(0);
    }
}
# Cmd error
else {
    die("Use --start or --stop in command!");
}

###
# Sign handling
###
my $FFMPEG;
my $ICECAST;

# close daemon on INT
$SIG{INT} = \&initSign;

###
# Advents options
###
my $noiceF          = "highpass=f=$lowpass, lowpass=f=$highpass";
my $silenceF        = "silencedetect=n=" . $silenceDb . "dB:d=$silenceSec";

# icecast
my $iceCastOpt      = "";
my $iceCastPid      = 0;

if ($iceCastLegacy) {
    $iceCastOpt     = "-legacy_icecast";    
}

# Start read data from webcam
my $ffmpegPid = open($FFMPEG, "ffmpeg -i $ipCamUrl -vn -af '$noiceF, $silenceF' -f rtp rtp://127.0.0.1:$intPort 2>&1 |");

while(my $line = <$FFMPEG>) {

    # Start voice
    if ($line =~ /silence_end/) {
        # start Icecast stream
        if ($iceCastUrl) {
            $iceCastPid = open($ICECAST, "ffmpeg -i rtp://127.0.0.1:$intPort -acodec libmp3lame -ar $sampleRate $iceCastOpt -f mp3 $iceCastUrl 2>&1 1> /dev/null |");
        }

        # send
        sendOpenHab("ON");
    }
    # End voice
    elsif ($line =~ /silence_start/) {
        # send
        sendOpenHab("OFF");

        # close Icecast stream
        if ($iceCastPid) {
            $daemon->Kill_Daemon($iceCastPid);
            close($ICECAST);

            $iceCastPid = 0;
        }
    }
}

close($FFMPEG);

sub initSign()
{
    $daemon->Kill_Daemon($iceCastPid);
    $daemon->Kill_Daemon($ffmpegPid);

    close($FFMPEG);
    close($ICECAST);
    exit(0);
}

sub sendOpenHab()
{
    my $cmd = shift;

    system("curl --header \"Content-Type: text/plain\" --request POST --data \"$cmd\" $openHabUrl/rest/items/$openHabItem");
}

