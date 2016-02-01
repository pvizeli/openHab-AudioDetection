# openHab-AudioDetection
Audio voice/noice detection from IP camera feed. If a audio/voice detect it can also stream to a icecast server for streaming with SONOS.

It take very small CPU performance. On Raspberry Pi2 B run the scan with 1.6% CPU usage. If it detect a noise/voice in the stream they can encode it as mp3 and stream it to icecast. This is optional but very usefully for some situation.

I wrote this program for use openHab with a IP-Cam (D-Link 2332L) as baby monitor.

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
- ```--openHabUrl```
- ```--openHabItem```
- ```--ipCamUrl```
- ```--intPort```
- ```--iceCastUrl```
- ```--iceCastLegacy```
- ```--highpass```
- ```--lowpass```
- ```--silenceDb```
- ```--silenceSec```
- ```--sampleRate```
- ```--pidFile```
- ```--start```
- ```--stop```
- ```--version```
- ```--help```

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

