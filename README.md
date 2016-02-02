# openHab-AudioDetection
Audio voice/noice detection from IP camera feed. If a audio/voice detect it can also stream to a icecast server for playing with SONOS.

It take very small CPU performance. On Raspberry Pi2 B run the scan with 1.6% CPU usage. If it detect a noise/voice in the audio stream they can encode it as mp3 and send that to icecast. This is optional but very usefully for some situation.The encoding process use 5-6% of cpu usage.

I wrote this program for use openHab with a IP-Cam (D-Link 2332L) as baby monitor.

## Audio filtering
Default it is optimize for human voice sound. It use a highpass filter with 300Hz and a lowpass filter from 2500Hz. This filter all frequenze with none human voice. Use this filter for reduce background noice.

## Audio silence detection
It detects that the input audio volume is less or equal to a noise tolerance value for a duration greater or equal to the minimum detected noise duration.

# Commandline

Start process:
```
audioDetection.pl --start [--pidFile=/tmp/audioDetection.pid] [--logFile=/tmp/myDetection.log] [--ffmpegBin=ffmpeg] [--curlBin=curl] --openHabUrl=http://192.168.1.10:8080 --openHabItem=Baby_Alarm --ipCamUrl=rtsp://192.168.1.11:554/live1.sdp [[--intPort=9554] --iceCastUrl=icecast://user:pw@192.168.1.12:8000/cam_audio.mp3 [--iceCastLegacy]] [--highpass=300] [--lowpass=2500] [--silenceDb=-30] [--silenceSec=20]
```

Stop process:
```
audioDetection.pl --stop [--pidFile=/tmp/audioDetection.pid]
```

## Instructions
- ```--openHabUrl``` URL to OpenHab web interface for rest API.
- ```--openHabItem``` Name of switch item for trigger the alarm.
- ```--ipCamUrl``` URL for cam live feed. It will ignore the video so you can use the live feed with low bandwidth.
- ```--intPort``` Port for internal RTP streaming. Default port is 9554.
- ```--iceCastUrl``` FFMPEG icecast URL. Is no URL defined, it'will not send the stream to icecast server.
- ```--iceCastLegacy``` Is the icecast server older than 2.4, set this flag.
- ```--highpass``` Cut all frequence lower than this value. Default is 300Hz.
- ```--lowpass``` Cut all frequence higher than this value. Default is 2500Hz.
- ```--silenceDb``` Noise tolerance value in Db. Default is -30Db.
- ```--silenceSec``` Duration of the minimum detected noise time. Default is 20 Sec.
- ```--sampleRate``` Scale up audio sample rate. For SONOS use minimal 16000 that is also the default value.
- ```--pidFile``` Set the pid file for deamon. For multible instance use multible pid file.
- ```--logFile``` Use a logfile for debug ouput. If don't set a file (default) it dosn't log.
- ```--start``` Start the program as daemon.
- ```--stop``` Stop a running daemon.
- ```--ffmpegBin``` Ffmpeg binary to use. Default is ffmpeg without a path.
- ```--curlBin``` Curl binary to use. Default is curl without a path.
- ```--version``` Print the version of the script.
- ```--help``` Print this URL out.

## Troubleshoting
If you have trouble please us the --logFile option to write a debug log. That will help in some cases.

# Install
This script use ffmpeg (not libav!) for audio analysing and streaming and curl for calling openHab rest API. Theoretical it work an all system they have perl, ffmpeg and curl. But for process handling I've only implement POSIX systems to use my script. Windows have a other process/service handling and I use this script on my raspberry. I've no time to spend for windows compatibility but you are free to delete all POSIX stuff in my script for use it on windows.

**Software:**
- Perl with Proc::Daemon
- ffmpeg with libmp3lame support
- curl
- icecast2 *(Optional)* for stream audio to i.e. SONOS
- openhab-addon-binding-exec

Copy the *audioDetection.pl* script to path they have access from openhab. That is all. Start an stop is possible from openhab with a switch.

## Debian
Install ffmpeg from multimedia backports http://www.deb-multimedia.org/.

```
sudo apt-get install curl libproc-daemon-perl icecast2
```

If you have a older icecast2 Server than 2.4, in my case Raspbian with Whessy, you need the flag --iceCastLegacy to work with older version.

### Raspberry
If you have Raspbian with jessie you can use multimedia backports if you don't need HW h264 support. For all other you need compile self. You need time for that...

**Compile:**
```
sudo apt-get remove --purge libtool libaacplus-* libx264 libvpx librtmp ffmpeg
sudo apt-get install curl libproc-daemon-perl icecast2 libmp3lame-dev
```

**x264**
```
git clone git://git.videolan.org/x264
cd x264
./configure --enable-static --disable-opengl
make
sudo make install
```

**ffmpeg**
```
git clone --depth 1 git://git.videolan.org/ffmpeg
cd ffmpeg
./configure --enable-gpl --enable-libx264 --enable-nonfree --enable-libmp3lame
make
sudo make install
```

# Configs

## OpenHab

**Note:** on Raspberry/Debien it is importet to use option --ffmpegBin/--curlBin with full path. The user openhab dosn't have the same PATH as a normal user.

```
Switch Babyphone_Alarm "Babyphone Alarm" (Child)
Switch Baby_Monitor "Babyphone" (Child) { exec="ON:perl@@audioDetection.pl@@--start@@--pidFile=/tmp/baby_monitor.pid@@--openHabUrl=http://192.168.1.10:8080@@--openHabItem=Babyphone_Alarm@@--ipCamUrl=rtsp://admin:pw@192.168.1.20/live3.sdp@@--iceCastLegacy@@--iceCastUrl=icecast://camUser:camPW@127.0.0.1:8000/baby_phone.mp3, OFF:perl@@audioDetection.pl@@--stop@@--pidFile=/tmp/baby_monitor.pid" }

```

## IceCast

```
<mount>
    <mount-name>/audio_stream.mp3</mount-name>

    <username>camUser</username>
    <password>camPW</password>
</mount>
```

