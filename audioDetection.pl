use strict;
use v5.10;

use POSIX;
use IO::File;
use Getopt::Long;
use Proc::Daemon;

###
# Static object
###
my $VERSION = "0.7";
my $daemon  = Proc::Daemon->new();

###
# audioDetection Options
###
my $openHabUrl;
my $openHabItem;
my $ipCamUrl;
my $intPort         = "9554";
my $iceCastUrl;
my $iceCastLegacy;
my $iceCastVol;
my $highpass        = "300";
my $lowpass         = "2500";
my $silenceDb       = "-30";
my $silenceSec      = "60";
my $sampleRate      = "16000";
my $pidFile         = "/tmp/audioDetection.pid";
my $pipeFile;
my $daemonStart     = "";
my $daemonStop      = "";
my $ffmpegBin       = "ffmpeg";
my $curlBin         = "curl";
my $logFile;

GetOptions(
    "openHabUrl:s"      => \$openHabUrl,
    "openHabItem:s"     => \$openHabItem,
    "ipCamUrl:s"        => \$ipCamUrl,
    "intPort=i"         => \$intPort,
    "iceCastUrl:s"      => \$iceCastUrl,
    "iceCastLegacy"     => \$iceCastLegacy,
    "iceCastVol:1"        => \$iceCastVol,
    "highpass=i"        => \$highpass,
    "lowpass=i"         => \$lowpass,
    "silenceDb=i"       => \$silenceDb,
    "silenceSec=i"      => \$silenceSec,
    "sampleRate=i"      => \$sampleRate,
    "ffmpegBin:s"       => \$ffmpegBin,
    "curlBin:s"         => \$curlBin,
    "pidFile=s"         => \$pidFile,
    "pipeFile:s"        => \$pipeFile,
    "start"             => \$daemonStart,
    "stop"              => \$daemonStop,
    "logFile:s"         => \$logFile,
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
my $PIPE;
my $LOGFILE;

# close daemon on INT
$SIG{INT} = \&initSign;

###
# Logfile things
###

if ($logFile) {
    $LOGFILE = IO::File->new(">> $logFile");
}

###
# Advents options
###
my $noiceF          = "highpass=f=$highpass, lowpass=f=$lowpass";
my $silenceF        = "silencedetect=n=" . $silenceDb . "dB:d=$silenceSec";

##
# IceCast
my $iceCastOpt      = "";
my $iceCastFilter   = "";

# old icecast vers
if ($iceCastLegacy) {
    $iceCastOpt     = "-legacy_icecast 1";
}

# vol
if ($iceCastVol) {
    $iceCastFilter  = "-af 'volume=volume=$iceCastVol'";
}

###
# Pipe
###

# Generate default
if (!$pipeFile) {
    $pipeFile       = $pidFile . ".pipe";
}

# don't exist pipe / create one
if (!-e $pipeFile) {
    POSIX::mkfifo($pipeFile, 0744);
}
# not a pipe
elsif (!-p $pipeFile) {
    unlink($pipeFile);
    POSIX::mkfifo($pipeFile, 0744);
}

###
# Main Loop
###
my $iceCastPid      = 0;
my $ffmpegPid       = 0;
my $okStream        = 0;

do {
    # open pipe
    $PIPE = IO::File->new("+< $pipeFile");

    # Start read data from webcam
    $ffmpegPid = open($FFMPEG, "$ffmpegBin -i $ipCamUrl -vn -af '$noiceF, $silenceF' -f rtp rtp://127.0.0.1:$intPort 2> $pipeFile |");

    # log
    $LOGFILE->say("FFMPEG start") if $logFile;

    # read data
    while(my $line = $PIPE->getline()) {
        # log
        $LOGFILE->print($line) if $logFile;

        # Start voice
        if ($line =~ /silence_end/) {
            $okStream = 1;

            # start Icecast stream
            if ($iceCastUrl) {
                $iceCastPid = open($ICECAST, "$ffmpegBin -i rtp://127.0.0.1:$intPort -acodec libmp3lame -ar $sampleRate $iceCastFilter $iceCastOpt -f mp3 $iceCastUrl 2> /dev/null |");

                # log
                $LOGFILE->say("IceCast start") if $logFile;
                sleep(1);
            }

            # send
            sendOpenHab("ON");
        }
        # End voice
        elsif ($line =~ /silence_start/) {
            $okStream = 1;

            # send
            sendOpenHab("OFF");

            # close Icecast stream
            if ($iceCastPid) {
                $daemon->Kill_Daemon($iceCastPid);
                close($ICECAST);

                $iceCastPid = 0;

                # log
                $LOGFILE->say("IceCast streaming end") if $logFile;
            }
        }
    }

    # close ffmpeg
    close($FFMPEG);

    # close pipe
    $PIPE->close();

    # log
    $LOGFILE->say("FFMPEG abrupt end!") if $logFile;

    # wait befor reconnect
    sleep(30);
} while($okStream);

# log
$LOGFILE->say("FFMPEG streaming end") if $logFile;
$LOGFILE->close() if $logFile;

###
# End
###

sub initSign()
{
    $LOGFILE->say("Receive SIGINT") if $logFile;

    # Send stop to openhab
    sendOpenHab("OFF") if $iceCastPid != 0;

    $daemon->Kill_Daemon($iceCastPid);
    $daemon->Kill_Daemon($ffmpegPid);

    # process handle
    close($FFMPEG);
    close($ICECAST);

    # file handle
    $PIPE->close();
    $LOGFILE->close() if $logFile;

    exit(0);
}

sub sendOpenHab()
{
    my $cmd = shift;

    system("$curlBin --header \"Content-Type: text/plain\" --request POST --data \"$cmd\" $openHabUrl/rest/items/$openHabItem");

    # log
    $LOGFILE->say("Send $cmd to openHab") if $logFile;
}
