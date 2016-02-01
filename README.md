# openHab-AudioDetection
Audio voice/noice detection from IP camera feed. If a audio/voice detect it can also stream to a icecast server for streaming with SONOS.

It take very small CPU performance. On Raspberry Pi2 B run the scan with 1.6% CPU usage. If it detect a noise/voice in the stream they can encode it as mp3 and stream it to icecast. This is optional but very usefully for some situation.The encoding process use 5-6% of cpu usage.

I wrote this program for use openHab with a IP-Cam (D-Link 2332L) as baby monitor.

## Audio filtering
Default it is optimize for human voice sound. It use a highpass filter with 300Hz and a lowpass filter from 2500Hz. This filter all frequenze with none human voice.

## Audio silence detection
It detects that the input audio volume is less or equal to a noise tolerance value for a duration greater or equal to the minimum detected noise duration.

# Commandline

Start process:
```
audioDetection.pl --start [--pidFile=/tmp/audioDetection.pid] --openHabUrl=http://192.168.1.10:8080 --openHabItem=Baby_Alarm --ipCamUrl=rtsp://192.168.1.11:554/live1.sdp [[--intPort=9554] --iceCastUrl=icecast://user:pw@192.168.1.12:8000/cam_audio.mp3 [--iceCastLegacy]] [--highpass=300] [--lowpass=2500] [--silenceDb=-30] [--silenceSec=20]
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
- ```--start``` Start the program as daemon.
- ```--stop``` Stop a running daemon.
- ```--version``` Print the version of the script.
- ```--help``` Print this URL out.

# Install

## Debian (Raspberry)

## OpenHab

## IceCast

```
<mount>
    <mount-name>/audio_stream.mp3</mount-name>

    <username>camUser</username>
    <password>camPW</password>
</mount>
```

