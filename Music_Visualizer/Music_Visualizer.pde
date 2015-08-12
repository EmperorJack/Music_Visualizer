import ddf.minim.*;
import ddf.minim.analysis.*;

/*
 * Jack Purvis
 * MDDN242: Project 2
 * MUSIC VISUALIZER
 */

// sketch fields
int w = 1024;
int h = 576;
int halfWidth = w / 2;
int halfHeight = h / 2;
float scaling;
int framerate = 60;

// delta time fields
float delta;
int targetFrameRate = 60;

// state and percentage fields
float pct;
float pctInc;
int state;

// documentation and hud fields
boolean displayHUD;
boolean displayDocumentation;
PFont font;
PImage docImage;

// colour fields
float hue;
float sat;
color colour;
float pctCol;

// audio fields
Minim minim;
AudioPlayer song;
LiveAudioReader audioReader;
float beatVal;
float volVal;

// particle system fields
ParticleSystem[] particleSystems;

// 3D fields
Shape3D[] volumeShapes;

// camera rotation
float[] camAngle;
float[][] camSpin;

// frame recording
boolean recordFrames = false;
int recordId = 0;

// audio data recording and replaying
boolean recordAudioData = false;
boolean replayAudioData = false;
ArrayList<Float> volVals = new ArrayList<Float>();
ArrayList<Float> beatVals = new ArrayList<Float>();

/*
 * Initialize the program.
 */
void setup() {
  // setup sketch
  size(w, h, P3D);
  colorMode(HSB, 360, 100, 100);

  // state and percentage setup
  pct = 0;
  pctInc = 0.0005;
  state = 0;

  // documentation and hud display setup
  displayHUD = false;
  displayDocumentation = false;
  font = createFont("CODE Bold.otf", 16);
  textFont(font, 16);
  docImage = loadImage("documentation.png");

  // determine proper sketch scaling
  scaling = min(w / 800f, h / 800f);

  // setup audio
  minim = new Minim(this);
  audioReader = new LiveAudioReader();
  if (recordAudioData) {
    song = minim.loadFile("deadmau5 feat. Chris James - The Veldt (Tommy Trash Remix).mp3");
  }
  beatVal = 0;
  volVal = 0;

  // setup particle systems
  particleSystems = new ParticleSystem[4];
  particleSystems[0] = new ParticleSystem(true, false, false, false, false);
  particleSystems[1] = new ParticleSystem(false, true, false, true, false);
  particleSystems[2] = new ParticleSystem(false, false, false, false, true);
  particleSystems[3] = new ParticleSystem(false, false, true, false, false);

  // setup 3D shapes
  volumeShapes = new Shape3D[4];
  volumeShapes[0] = new Shape3D("shape1a.obj", "shape1b.obj", 1, -1, 1);
  volumeShapes[1] = new Shape3D("shape2a.obj", "shape2b.obj", 0, 0, 0);
  volumeShapes[2] = new Shape3D("shape3a.obj", "shape3b.obj", 0, -1, 0);
  volumeShapes[3] = new Shape3D("shape4a.obj", "shape4b.obj", 0, 1, 0);

  // setup camera rotations
  camAngle = new float[3];
  camSpin = new float[][] {
    {
      -0.28, 0.2, -0.24
    }
    , {
      0.14, -0.18, 0.22
    }
    , {
      -0.1, 0.4, -0.1
    }
    , {
      0.25, -0.15, 0.2
    }
  };

  // play the track if recording or replaying audio data
  if (recordAudioData) {
    song.play();
  }

  // load audio data if replay intended
  if (replayAudioData) {
    loadAudioData();
  }
}

/*
 * Main program loop. Performs delta time operations.
 */
void draw() {
  delta = targetFrameRate / frameRate;
  tick();
}

/*
 * Tick method for performing program updates and drawing.
 */
void tick() {
  // interpret the live audio data from minim
  if (!replayAudioData) {
    audioReader.readLiveVolume();
    audioReader.readLiveBeats();
  }
  
  // draw the sketch background receptive to the current colour
  background(color(hue, 50, (volVal * beatVal) * 20 + 10));

  // use lights
  lights();
  ambientLight(255, 255, 255);

  pushMatrix();

  // translate to sketch center
  translate(halfWidth, halfHeight, -350);

  // scale sketch to proper size
  scale(scaling);

  // rotate the camera
  rotateX(radians(camAngle[0] += (camSpin[state][0] * delta)));
  rotateY(radians(camAngle[1] += (camSpin[state][1] * delta)));
  rotateZ(radians(camAngle[2] += (camSpin[state][2] * delta)));

  // update the colour cycle
  colourUpdate();

  // update the state cycle
  stateUpdate();

  // update and draw the particle system
  particleSystems[state].update();

  // update and draw the 3D volume shape
  volumeShapes[state].update();

  popMatrix();

  // display hud information if enabled
  if (displayHUD) {
    drawHUD();
  }

  // display documentation information if enabled
  if (displayDocumentation) {
    drawDocumentation();
  }

  // save a frame
  if (recordFrames) {
    saveFrame("recordedFrames/frame_" + recordId + ".tga");
    recordId++;
  }

  // record audio data
  if (recordAudioData) {
    volVals.add(volVal);
    beatVals.add(beatVal);

    // check if song ended
    if (!song.isPlaying()) {
      // stop program as recording finished
      stop();
    }
  }

  // replay audio data
  if (replayAudioData) {
    if (frameCount < volVals.size()) {
      volVal = volVals.get(frameCount);
      beatVal = beatVals.get(frameCount);
    } else {
      // if song ended
      stop();
    }
  }
}

/*
 * Update the visualizer colour based on current percent.
 */
void colourUpdate() {
  // increment the colour percent
  pctCol += (pctInc * delta);
  if (pctCol >= 1) {
    pctCol = 0;
  }

  // hue calculated from percent
  hue = map(pctCol, 0, 1, 0, 360);

  // saturation calculated from beat value
  sat = 100 - (beatVal) * 20;

  colour = color(hue, sat, 100);
}

/*
 * Update the visualizer state based on current percent.
 */
void stateUpdate() {
  // increment the state percent
  pct += (pctInc * delta);
  if (pct >= 1) {
    toggleState();
  }
}

/*
 * Toggle the visualzier to the next state.
 */
void toggleState() {
  state++;
  if (state == 4) {
    state = 0;
  }

  // reset the percentage
  pct = 0;

  // reset the current particle system in this state
  particleSystems[state].reset();
}

/*
 * When a keyboard key is pressed
 */
void keyPressed() {
  if (key == ' ') {
    toggleState();
  } else if (key == 'd') {
    displayHUD = !displayHUD;
  } else if (key == 'h') {
    displayDocumentation = !displayDocumentation;
  } else if (key == 's') {
    stop();
  } else if (key == 'f') {
    if (framerate == 30) {
      framerate = 60;
    } else {
      framerate = 30;
    }
    frameRate(framerate);
  }
}

/*
 * Draw sketch statistics in the top left corner.
 */
void drawHUD() {
  fill(color(hue, 100, 100));
  scale(scaling);

  // draw the statistics as text
  text("FPS: " + (int) frameRate, 15, 30);
  text("State: " + state, 15, 60);
  text("State Percent: " + (int) (pct * 100) + "%", 15, 90);
  text("Particle Count: " + particleSystems[state].particleNum, 15, 120);
}

/*
 * Draw the documentation text for the music visualizer.
 */
void drawDocumentation() {
  scale(scaling);
  noStroke();

  // draw an overlay over the visualizer
  fill(color(0, 0, 0), 220);
  rect(0, 0, width, height);

  // draw the text documentation
  fill(color(hue, 100, 100));

  image(docImage, 0, 0);
}

void loadAudioData() {
  // load in the data
  String[] volValsString = loadStrings("recordedAudio/volVals.txt");
  String[] beatValsString = loadStrings("recordedAudio/beatVals.txt");

  // convert each float value to a string
  for (int i = 0; i < volValsString.length; i++) {
    volVals.add(float(volValsString[i]));
    beatVals.add(float(beatValsString[i]));
  }
}

void stop() {
  // stop minim properly
  audioReader.stopMinim();

  // save out recorded audio data
  if (recordAudioData) {
    // output data must be strings
    String[] volValsString = new String[volVals.size()];
    String[] beatValsString = new String[beatVals.size()];

    // convert each float value to a string
    for (int i = 0; i < volVals.size (); i++) {
      volValsString[i] = volVals.get(i).toString();
      beatValsString[i] = beatVals.get(i).toString();
    }

    // save out the data
    saveStrings("recordedAudio/volVals.txt", volValsString);
    saveStrings("recordedAudio/beatVals.txt", beatValsString);
  }

  exit();
}

