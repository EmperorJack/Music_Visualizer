/*
 * A class for a 3D shape which uses two obj objects and interpolates between them.
 */
class Shape3D {

  // 3D state 1
  PShape state01;

  // 3D state 2
  PShape state02;

  // Interpolated 3D state
  PShape state;

  // Shape rotation
  float[] angle;
  float[] spin;

  /**
   * Setup a new 3D shape.
   */
  Shape3D(String fName01, String fName02, float rX, float rY, float rZ) {
    // load the obj files
    state01 = loadShape(fName01).getTessellation();
    state02 = loadShape(fName02).getTessellation();
    state = loadShape(fName01).getTessellation();
    state.disableStyle();

    // setup shape rotation
    angle = new float[3];
    spin = new float[] {
      rX, rY, rZ
    };
  }

  /**
   * Update the 3D shape.
   */
  void update() {
    // interpolate vertex position values between the states depending on the volume value

      // for each vertex
    for (int i = 0; i < state01.getVertexCount (); i++) {
      // get both state position vectors
      PVector v1 = state01.getVertex(i);
      PVector v2 = state02.getVertex(i);

      // interpolate the vector positions
      float x = map(volVal, 0, 1, v1.x, v2.x);
      float y = map(volVal, 0, 1, v1.y, v2.y);
      float z = map(volVal, 0, 1, v1.z, v2.z);

      // apply the new vector position to the interpolated shape
      state.setVertex(i, new PVector(x, y, z));
    }

    // draw the 3D shape
    drawShape();
  }

  /**
   * Draw the 3D shape.
   */
  void drawShape() {
    pushMatrix();

    // shape display settings
    strokeWeight(1.2);
    stroke(colour);
    fill(color(hue, 100, volVal * 60 + 20));

    // scale the shape
    scale(120);

    // rotate the shape
    rotateX(radians(angle[0] += (spin[0] * delta)));
    rotateY(radians(angle[1] += (spin[1] * delta)));
    rotateZ(radians(angle[2] += (spin[2] * delta)));
        
    shape(state);

    popMatrix();
  }
}