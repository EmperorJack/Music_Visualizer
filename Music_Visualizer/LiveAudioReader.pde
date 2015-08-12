/*
 * A class for reading live audio data from the stero mix. Uses minim for volume and
 * beat detection.
 */
class LiveAudioReader {

  // minim fields
  BeatDetect beat;
  BeatListener bl;
  AudioInput in;

  // audio fields
  float curVol;
  float lastVol;

  /*
   * Setup a new audio reader using minim.
   */
  LiveAudioReader() {
    // setup minim fields
    in = minim.getLineIn(Minim.STEREO, 2048);
    beat = new BeatDetect(in.bufferSize(), in.sampleRate());
    beat.setSensitivity(0);
    bl = new BeatListener(beat, in);

    // setup audio
    curVol = 0;
    lastVol = 0;
  }

  /*
   * Read the volume input for the live audio.
   */
  void readLiveVolume() {
    // get the current volume level
    curVol = in.mix.level();

    float volDiff = 0;

    // check the current volume is at an acceptable level
    if (curVol > 0.0005) {
      // find the change in volume since last call
      volDiff = (curVol / lastVol) - 1;
    } 

    // if the volume changed enough
    if (volDiff > 0.1) {
      // bump up the volume value
      volVal += (volDiff * delta);
    }

    // constrain the volume value
    volVal = constrain(volVal, 0, 1);

    if (volVal < 0.005) {
      // clamp to 0 if small enough
      volVal = 0;
    } else {
      // decrease the volume value
      volVal = constrain(volVal * pow(0.95, delta), 0, 1);
    }

    // cycle the current volume value for next call
    lastVol = curVol;
  }

  /*
   * Read the beat input for the live audio.
   */
  void readLiveBeats() {
    // if a type of beat was found bump up the beat value
    if (beat.isHat()) beatVal += (0.18 * delta);
    if (beat.isSnare()) beatVal += (0.22 * delta);
    if (beat.isKick()) beatVal += (0.25 * delta);

    // constrain the beat value
    beatVal = constrain(beatVal, 0, 1);

    if (beatVal < 0.005) {
      // clamp to 0 if small enough
      beatVal = 0;
    } else {
      // decrease the beat value
      beatVal = constrain(beatVal * pow(0.85, delta), 0, 1);
    }
  }

  /*
   * Upon the sketch stopping halt minim.
   */
  void stopMinim() {
    in.close();
    minim.stop();
  }

  /*
   * BeatListener class provided by minim.
   */
  class BeatListener implements AudioListener {
    private BeatDetect beat;
    private AudioInput source;

    BeatListener(BeatDetect beat, AudioInput source)
    {
      this.source = source;
      this.source.addListener(this);
      this.beat = beat;
    }

    void samples(float[] samps)
    {
      beat.detect(source.mix);
    }

    void samples(float[] sampsL, float[] sampsR)
    {
      beat.detect(source.mix);
    }
  }
}

