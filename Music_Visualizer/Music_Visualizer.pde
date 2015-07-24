import ddf.minim.*;
import ddf.minim.analysis.*;

/*
 * Jack Purvis
 * MDDN242: Project 2
 * MUSIC VISUALIZER
 */

// sketch fields
int w = 1000;
int h = 1000;
int halfWidth = w / 2;
int halfHeight = h / 2;
float scaling;

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
  scaling = min(w / 1000f, h / 1000f);

  // setup audio
  minim = new Minim(this);
  audioReader = new LiveAudioReader();
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
}

/*
 * Main program loop.
 */
void draw() {
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
  rotateX(radians(camAngle[0] += camSpin[state][0]));
  rotateY(radians(camAngle[1] += camSpin[state][1]));
  rotateZ(radians(camAngle[2] += camSpin[state][2]));

  // interpret the live audio data from minim
  audioReader.readLiveVolume();
  audioReader.readLiveBeats();

  // update the colour cycle
  colourUpdate();

  // update teh state cycle
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
}

/*
 * Update the visualizer colour based on current percent.
 */
void colourUpdate() {
  pctCol += pctInc;
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
  pct += pctInc;
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

