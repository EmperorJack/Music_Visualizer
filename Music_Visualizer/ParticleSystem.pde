/*
 * A class for a particle system that has many properties and generates particles
 * that draw lines between eachother.
 */
class ParticleSystem {
  // particle fields
  ArrayList<Particle> particles = new ArrayList<Particle>();
  int particleMax = 400;
  int particleNum = 0;

  // line threshold and max lines per particle
  int linesRad = 75;
  int linesMax = 3;

  // particle velocity fields
  float velMin = 0.5;
  float velMax = 1.5;
  float velMult = 8;

  // bound and range
  float range = 800;
  float bound = 350;

  // system properties
  boolean diverge;
  boolean despawnCenter;
  boolean singlePlane;
  boolean triplePlane;
  boolean tornado;

  // system origin
  int psX = 0;
  int psY = 0;
  int psZ = 0;
  PVector origin = new PVector(psX, psY, psZ);

  /*
   * Setup a new particle system.
   */
  ParticleSystem(boolean diverge, boolean despawnCenter, boolean singlePlane, boolean triplePlane, boolean tornado) {
    this.diverge = diverge;
    this.despawnCenter = despawnCenter;
    this.singlePlane = singlePlane;
    this.triplePlane = triplePlane;
    this.tornado = tornado;
  }

  /*
   * Update the particle system.
   */
  void update() {
    // create new particles
    if (particleNum < particleMax && frameCount % 1 == 0) {
      particles.add(new Particle());
      particleNum++;
    }

    // update each particle position
    for (Particle p : particles) {
      p.update(velMult);
    }
    
    strokeWeight(1.2);

    // compute and draw the lines coming from each particle
    for (int i = 0; i < particles.size(); i++) {
      particles.get(i).lines(i + 1);
    }
    
    noStroke();

    // draw each particle
    for (Particle p : particles) {
      p.drawParticle();
    }
  }

  /*
   * Reset the particle system to default state.
   */
  void reset() {
    particles.clear();
    particleNum = 0;
  }

  /*
   * A class for an individual particle within a system.
   */
  class Particle {
    // particle vector fields
    PVector pos;
    PVector vel;

    // connected particle fields
    int linesNum;

    /*
     * Setup a new particle.
     */
    Particle () {
      resetParticle();
    }

    /*
     * Update the particle position.
     */
    void update(float velMult) {
      // check if out of bounds for reset
      if (outOfBounds()) {
        resetParticle();
      }

      // move the particle
      // velocity multiplies on current beat value
      PVector inc = PVector.mult(vel, (velMult * beatVal) + 1);
      pos.add(PVector.mult(inc, delta));
    }
    
    /*
     * Compute and draw the lines coming from this particle.
     */
    void lines(int start) {
      linesNum = 0;
      
      // for each other particle from the start index
      for (int i = start; i < particles.size(); i++) {
        
        // if the other particle is close enough
        if (pos.dist(particles.get(i).pos) < linesRad) {
          
          // set line opactiy to vary with beat value and distance to origin or bounds
          stroke(colour, beatVal * distOpacity());

          // draw a line from this particle to the other particle
          line(pos.x, pos.y, pos.z, particles.get(i).pos.x, particles.get(i).pos.y, particles.get(i).pos.z);

          // increment line counter
          linesNum++;
        }

        // check if the particle has reached the maximum number of lines
        if (linesNum == linesMax) {
          break;
        }
      }
    }

    /*
     * Draw the particle.
     */
    void drawParticle() {
      pushMatrix();

      // translate to particle depth
      translate(pos.x, pos.y, pos.z);

      // make the ellipse face the camera
      rotateX(-radians(camAngle[0]));
      rotateY(-radians(camAngle[1]));
      rotateZ(-radians(camAngle[2]));
      
      // particle opactiy varies distance to origin or bounds
      fill(colour, distOpacity() - 30);

      // draw the particle
      ellipse(0, 0, -3, 3);

      popMatrix();
    }

    /*
     * Check if the particle has left the sketch bounds or should despawn
     * at the system origin if close to it.
     */
    boolean outOfBounds() {
      // if particle is outside of range
      if (pos.dist(origin) > range + 50) {
        return true;
      }

      // particle is too close to system origin
      if (despawnCenter && pos.dist(origin) < 50) {
        return true;
      }

      return false;
    }

    /*
     * Reset the particle position and velocity.
     */
    void resetParticle() {
      if (diverge) {
        // diverge from system origin
        pos = new PVector(psX, psY, psZ);
      } else {
        // generate a random position to converge
        pos = randomSpherePoint(range);
      }
      // generate a random velocity
      vel = randomVelocity();
    }

    /*
     * Generate a random direction velocity vector.
     */
    PVector randomVelocity() {
      // generate a random speed value
      float speed = random(velMin, velMax);

      if (diverge) {
        // diverge at a random angle from the system origin
        float angle = random(TWO_PI); 
        return new PVector(speed * cos(angle), speed * sin(angle), random(-1, 1));
      } else {
        // converge towards the system origin
        vel = PVector.sub(origin, pos);
        vel.normalize();
        return PVector.mult(vel, speed);
      }
    }

    /*
     * Returns a random point on a sphere of the given radius. The sphere
     * is centered at the particle system origin.
     */
    PVector randomSpherePoint(float radius) {
      // generate a random point on surface of sphere
      float theta = TWO_PI * random(0, 1);
      float phi = acos(2 * random(0, 1) - 1);
      float x = (psX + radius * sin(phi) * cos(theta));
      float y = (psY + radius * sin(phi) * sin(theta));
      float z = (psZ + radius * cos(phi));

      // depending on system properties assign position values relative to planes

      if (triplePlane) {
        int rand = (int) random(0, 3);
        if (rand == 0) {
          x = 0;
        } else if (rand == 1) {
          y = 0;
        } else {
          z = 0;
        }
      }

      if (tornado) {
        int rand = (int) random(0, 2);
        if (rand == 0) {
          y = -700;
        } else {
          y = 700;
        }
      }

      if (singlePlane) {
        y = 0;
      }

      return new PVector(x, y, z);
    }

    /*
     * If the particle is a certain distance from the origin or bounds return
     * an opactity value so it can fade in or out.
     */
    float distOpacity() {
      // distance between the particle and system origin
      float dist = pos.dist(origin);

      if (dist < bound) {
        // particle is close to center
        return map(dist, 100, bound, 0, 200);
      } else if (range - dist < bound) {
        // particle is close to bounds
        return map(range - dist, 100, bound, 0, 200);
      }
      return 200;
    }
  }
}