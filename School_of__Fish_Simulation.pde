// Although I did not copy any code directly from any sources, I did reference Daniel Shiffman's 
//book/online guide, the Nature of Code, while writing this program. Nature of Code can be found here:
//http://natureofcode.com/book/

School school;
ObstacleList obstacleList;
boolean isFood = false;// if cursor should be food
boolean isPredator = false;// if cursor should be predator

void setup() {
  size(1500, 1500);
  obstacleList = new ObstacleList();
  school = new School();
  for (int i = 0; i < 150; i++) {//spawn inital school of fish at random postions
    school.addFish(new Fish(random(0, width), random(0, height)));
  }
}
void draw() {
  background(0, 20, 100);
  school.run();//simulate the School
  obstacleList.run();//simulate the obstacles
  draw_buttons();// draw food and predator buttons
  if (isPredator == true) {
    PVector mouseHeading = new PVector(mouseX-pmouseX, mouseY-pmouseY, 0);
    draw_predator(mouseHeading);
  }
  if (isFood == true) {
    drawfood();
  }
}
void mousePressed() {// for pressing buttons and placing obstacles
  if (((mouseX < width-10)&&(mouseY>10)) && ((mouseX > width-110)&&(mouseY<60))) {
    isFood = true;
    isPredator = false;
  } else if (((mouseX < width-10)&&(mouseY>70)) && ((mouseX > width-110)&&(mouseY<120))) {
    isPredator = true;
    isFood = false;
  } else {
    isPredator = false;
    isFood = true;
    obstacleList.addObstacle(new Obstacle(mouseX, mouseY));
  }
}
void drawfood() {// draws green dot for cursor when it is acting as food
  fill(20, 255, 20);
  stroke(0);
  ellipse(mouseX, mouseY, 25, 25);
}
void draw_buttons() {
  fill(20, 240, 20);
  stroke(255);
  rect(width-110, 10, 100, 50);
  fill(0);
  text("Food", width-75, 40, 0);
  fill(240, 20, 20);
  stroke(255);
  rect(width-110, 70, 100, 50);
  fill(0);
  text("Predator", width-81, 100, 0);
}
void draw_predator(PVector direction) {
  fill(200, 20, 20);
  stroke(200, 20, 20);
  pushMatrix();
  translate(mouseX, mouseY);
  rotate(direction.heading()+radians(90));
  ellipse(0, 0, 25, 100);

  beginShape();
  vertex(-10, 30);
  vertex(-5, 60);
  vertex(-2, 90);
  vertex(2, 90);
  vertex(5, 60);
  vertex(10, 30);
  endShape();

  beginShape();
  vertex(-2, 90);
  vertex(-25, 105);
  vertex(-25, 110);
  vertex(0, 105);
  vertex(25, 110);
  vertex(25, 105);
  vertex(2, 90);
  endShape();

  beginShape();
  vertex(0, -20);
  vertex(-15, -5);
  vertex(-35, 10);
  vertex(-45, 25);
  vertex(0, 0);
  vertex(45, 25);
  vertex(35, 10);
  vertex(15, -5);
  vertex(0, -20);
  endShape();

  popMatrix();
}
class Obstacle {// class for creating obstcles
  PVector Position;
  Float Radius;

  Obstacle(int x, int y) {
    Position = new PVector(x, y);
    Radius = random(50, 100);
  }
  void drawObstacle() {
    fill(200);
    stroke(255);
    ellipse(Position.x, Position.y, Radius, Radius);
  }
}
class ObstacleList {
  ArrayList<Obstacle> obstacles;

  ObstacleList() {
    obstacles = new ArrayList<Obstacle>();
  }
  void run() {
    for (Obstacle o : obstacles) {
      o.drawObstacle();
    }
  }
  void addObstacle(Obstacle o) {
    obstacles.add(o);
  }
}

class School {// class for organizing fish objects
  ArrayList<Fish> fishes;
  School() {
    fishes = new ArrayList<Fish>();
  }
  void addFish(Fish b) {
    fishes.add(b);
  }
  void run() {
    for (Fish f : fishes) {
      f.run(fishes, obstacleList.obstacles, isPredator, isFood);
    }
  }
}
//Class that describes a "fish". This is where the magic happens
class Fish {
  PVector position;
  PVector velocity;
  PVector acceleration;
  PVector horizontal;// for flashing scales effect
  Float fishScale;// determins size of fish drawn
  Float maxturn;// makes swimming look natural
  Float maxspeed;//prevents fish accerating to extreme speeds
  Float optimalSpacing;//minimum spacing between fish when grouped together
  Float fishColor;
  boolean isPredator; 
  //distances for each area of influence
  float alignDistance;
  float cohesionDistance;
  float separationarationDistance;

  Fish(Float x, Float y) {
    acceleration = new PVector(0, 0);
    velocity = PVector.random2D();
    horizontal = new PVector(5, 0, 0);
    position = new PVector(x, y);
    fishScale = random(2, 7); 
    maxspeed = 2.0;
    maxturn = 0.03;
    fishColor = 200.0;
    alignDistance = 50.0;
    cohesionDistance = 500.0;
    separationarationDistance = 30.0;
  }
  //simulates movement of 1 fish
  void run(ArrayList<Fish> fishes, ArrayList<Obstacle> obstacles, boolean ispredator, boolean isfood) {
    School(fishes, obstacles, ispredator, isfood);
    updateFish();
    borders();
    drawFish();
    //drawFish();
  }
  //adds acceleration vectors to fishes acceleration
  void addAcceleration(PVector force) {
    acceleration.add(force);
  }
  //calculates all the accelleration vector for a single fish based on whats around them
  void School(ArrayList<Fish> fishes, ArrayList<Obstacle> obstacles, boolean ispredator, boolean isfood) {
    //initalizes all the Accleration PVectors that will eventually be calculated and added to acceleration
    PVector separation = separate(fishes);   // separationaration
    PVector align = align(fishes);      // Alignment
    PVector cohesion = cohesion(fishes);   // Cohesion
    PVector mouseparationosition = new PVector(mouseX, mouseY);
    PVector findFood = new PVector(0, 0, 0);
    PVector avoidPredator = new PVector(0, 0, 0);
    PVector AvoidObstacle = avoidObstacles(obstacles);
    //checks for food and predator behavior
    if (ispredator == true) {
      avoidPredator = avoidTarget(mouseparationosition);
    }
    if (isfood == true) {
      findFood = seek(mouseparationosition);
    }
    // weight them all so they fish swim realistically
    separation.mult(2.0);
    align.mult(1);
    cohesion.mult(1);
    findFood.mult(1.5);
    avoidPredator.mult(5.0);
    AvoidObstacle.mult(3.0);

    addAcceleration(separation);
    addAcceleration(align);
    addAcceleration(cohesion);
    addAcceleration(findFood);
    addAcceleration(avoidPredator);
    addAcceleration(AvoidObstacle);
  }
  void drawDot() {
    Float theta = velocity.heading() + radians(90);
    fishColor = 150.0;
    if (abs(PVector.angleBetween(horizontal, velocity)) < radians(15)) {
      fishColor = 245.0;
    }
    fill(fishColor);
    stroke(200);
    pushMatrix();
    translate(position.x, position.y);
    ellipse(0, 0, fishScale, fishScale);
    popMatrix();
  }
  void drawFish() {
    Float theta = velocity.heading() + radians(90);
    fishColor = 150.0;
    if (abs(PVector.angleBetween(horizontal, velocity)) < radians(15)) {
      fishColor = 245.0;
    }
    fill(fishColor);
    stroke(200);
    pushMatrix();
    translate(position.x, position.y);
    rotate(theta);
    ellipse(0, 0, fishScale, 4*fishScale);
    beginShape(TRIANGLES);
    vertex(0, fishScale*2);
    vertex(-fishScale*1.2, fishScale*3);
    vertex(fishScale*1.2, fishScale*3);
    endShape();
    popMatrix();
  }
  //updates fish movement by changing a fishes postion and velocity
  void updateFish() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
  }
  //makes fish seek a certain postion on the screen. Used in cohesion and for seeking cursor when in food mode
  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);
    desired.setMag(maxspeed);
    PVector turn = PVector.sub(desired, velocity);
    turn.limit(maxturn);
    return turn;
  }
  //makes sure fish stay on the screen
  void borders() {
    if (position.x < -fishScale) position.x = width+fishScale;
    if (position.y < -fishScale) position.y = height+fishScale;
    if (position.x > width+fishScale) position.x = -fishScale;
    if (position.y > height+fishScale) position.y = -fishScale;
  }
  //calculates the cohesion vector for a single fish
  PVector cohesion (ArrayList<Fish> fishes) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Fish other : fishes) {
      Float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < cohesionDistance)) {
        sum.add(other.position);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return seek(sum);
    } else {
      return new PVector(0, 0);
    }
  }
  //calculates separation vector for a fish
  PVector separate(ArrayList<Fish> fishes) {
    PVector turn = new PVector(0, 0, 0);
    int count = 0;
    for (Fish other : fishes) {
      Float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < separationarationDistance) && (abs(PVector.angleBetween(velocity, other.velocity)) < radians(60))) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d);
        turn.add(diff);
        count++;
      }
    }
    if (count > 0) {
      turn.div((float)count);
    }
    if (turn.mag() > 0) {
      turn.setMag(maxspeed);
      turn.sub(velocity);
      turn.limit(maxturn);
    }
    return turn;
  }
  //calculates the align vector for a fish
  PVector align(ArrayList<Fish> fishes) {
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Fish other : fishes) {
      Float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < alignDistance) && (abs(PVector.angleBetween(velocity, other.velocity)) < radians(60))) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div((float)count);
      sum.setMag(maxspeed);
      PVector turn = PVector.sub(sum, velocity);
      turn.limit(maxturn);
      return turn;
    } else {
      return new PVector(0, 0);
    }
  }
  //calculates a vector pointing directly away from a point on the screen. used for predator mode
  PVector avoidTarget(PVector mouseparationosition) {
    Float safeDistance = 200.0f;
    PVector direction = new PVector(0, 0, 0);
    Float distance = PVector.dist(position, mouseparationosition);
    if (distance < safeDistance) {
      PVector diff = PVector.sub(position, mouseparationosition);
      diff.normalize();
      diff.div(distance);
      direction.add(diff);
    }
    if (direction.mag() > 0) {
      direction.setMag(maxspeed);
      direction.sub(velocity);
      direction.limit(maxturn);
    }
    return direction;
  }
  //calcualtes acceleration vector for avoiding an obstacle
  PVector avoidObstacles(ArrayList<Obstacle> obstacles) {
    PVector turn = new PVector(0, 0, 0);
    if (obstacles != null) {
      Float clearance = 50.0f;
      for (Obstacle obstacle : obstacles) {
        Float d = PVector.dist(position, obstacle.Position);
        if ((d > 0) && (d < obstacle.Radius + clearance)) {
          PVector diff = PVector.sub(position, obstacle.Position);
          if (PVector.angleBetween(diff, velocity) < radians(30)) {
            diff.rotate(radians(60));
          }
          diff.normalize();
          diff.div(d);
          turn.add(diff);
        }
      }
      if (turn.mag() > 0) {
        turn.setMag(maxspeed);
        turn.sub(velocity);
        turn.limit(maxturn);
      }
    }
    return turn;
  }
}