Walls map; 
PVector light;
ArrayList<ArrayList<PVector>> Buildings; 
ArrayList<ArrayList<PVector>> LOS; 
ArrayList<PVector> shadows; 
int border = 30;

void setup() {
 fill(255); 
 size(500, 500); 
 
 Buildings = new ArrayList<ArrayList<PVector>>(); 
 ArrayList<PVector> b1 = new ArrayList<PVector> (); 
 b1.add(new PVector (150.0, 160.0)); 
 b1.add(new PVector (70.0, 140.0)); 
 b1.add(new PVector (120.0, 200.0));

 
 Buildings.add(b1); 
 
 map = new Walls(Buildings); 
 map.addWall(new PVector(100, 300), new PVector(300, 350));
 map.addWall(new PVector (border, border), new PVector(width - border, border)); 
 map.addWall(new PVector (width - border, border), new PVector (width - border, height - border)); 
 map.addWall(new PVector (width - border, height - border), new PVector(border, height - border)); 
 map.addWall(new PVector (border, height - border), new PVector(border, border)); 
 light = new PVector (0.75 * 500, 0.25 * 500); 
 
 LOS = map.sweep(light); 
 shadows = map.getShadows(LOS, map.endPoints, light); 
 background(0); 
 

 map.display(); 
 fill(#FFFF00); 
 noStroke(); 
 ellipse (light.x, light.y, 10, 10); 
 
 noLoop(); 
}

void draw() {
  background(0); 
  light.x = mouseX; 
  light.y = mouseY;
  LOS = map.sweep(light); 
  shadows = map.getShadows(LOS, map.endPoints, light); 

 beginShape(); 
  fill(#FFFF00, 50);   //display points in LOS and Shadows 
  
  
  
  for (int i = 0; i < LOS.size(); i ++) {
    for (int j = 0; j < LOS.get(i).size(); j++) {
      fill (#2F9F9F); 
      ellipse (LOS.get(i).get(j).x, LOS.get(i).get(j).y, 10, 10); 
      stroke (#2F3FA7); 
      line(light.x, light.y, LOS.get(i).get(j).x, LOS.get(i).get(j).y); 
    }
  }
  
  for (int j = 0; j < shadows.size(); j ++) {
    fill(#CB329F); 
    ellipse(shadows.get(j).x, shadows.get(j).y, 10, 10); 
    
  }
  
  endShape(); 
  map.display();

  ellipse(light.x, light.y, 10, 10);
  //LOS
  
  
  fill(#FFFF00); 
  noStroke(); 
  ellipse (light.x, light.y, 10, 10); 
  noLoop(); 
  
}

void mouseMoved() {
  loop(); 
}


class Walls {
  ArrayList<Wall> walls; 
  ArrayList<Endpoint> endPoints, sortedEndPoints; 
  
  ArrayList<Integer> indices; 
  int counter = 0; 
  Walls(ArrayList<ArrayList<PVector>> buildings) {
    walls = new ArrayList<Wall>(); 
    endPoints = new ArrayList<Endpoint>(); 
    sortedEndPoints = new ArrayList<Endpoint>(); 
    converttowalls(buildings); 
    
  }
  //converts buildings to walls
  
  void converttowalls (ArrayList<ArrayList<PVector>> buildings) {
    
    for (ArrayList<PVector> bld: buildings) {
      for (int index = 0; index < bld.size(); index ++) {
        if (index == (bld.size() - 1)) {
          addWall(bld.get(index), bld.get(0)); 
        } else {
          addWall(bld.get(index),bld.get(index + 1)); 
        }
      }
    }
    
  }
  void addWall(PVector begin, PVector end) {
    
    walls.add(new Wall(begin, end, counter)); 
    addEndPoint(begin, counter); 
    addEndPoint(end, counter); 
    counter ++; 
  }
  
  void addEndPoint(PVector point, int index) {
    boolean duplicate = false; 
    for (int i = 0; i < endPoints.size(); i++) {
      if (point.x == endPoints.get(i).location.x && point.y == endPoints.get(i).location.y) {
        duplicate = true; 
        endPoints.get(i).addIndex(index); 
        break; 
      }
    }
   
    if (!duplicate) {
      endPoints.add(new Endpoint(point, index)); 
    }
    
    
  }
  
  void display() {
    
    for (int i = 0; i < walls.size(); i ++) {
      walls.get(i).display(); 
    }
    
    for (int i = 0; i < endPoints.size(); i ++) {
      endPoints.get(i).display(); 
    }
  }
  
  //obtains endpoints on screen
  ArrayList<ArrayList<PVector>> sweep (PVector source) {
    
    ArrayList<ArrayList<PVector>> LineOfSight = new ArrayList<ArrayList<PVector>>();   
    //Calculate End Point angles from source
    for (int i = 0; i < endPoints.size(); i ++) {
      endPoints.get(i).sourceangle(source); 
    }
    
    //calculate closest distance of each wall from source
    for (int i = 0; i < walls.size(); i ++) {
      walls.get(i).sourceClosestDistance(source); 
    }
  
    //Sorts End Points by angle from source 
    ArrayList<Endpoint> sortedEndPoints = new ArrayList<Endpoint>(); 
    sortedEndPoints.clear(); 
    sortedEndPoints.add(endPoints.get(0)); 
    boolean sorted; 
    for (int i = 1; i < endPoints.size(); i++) {
      sorted = false; 
      for (int j = 0; j < sortedEndPoints.size(); j ++) {
        if (sortedEndPoints.get(j).angle > endPoints.get(i).angle) {
          sortedEndPoints.add(j, endPoints.get(i));
          sorted = true; 
          break; 
        }
      }
      
      if (!sorted) {
        sortedEndPoints.add(endPoints.get(i)); 
      }
     }
         
  
    //Iterates through Endpoints, finding wall intersections 
    ArrayList<Integer> intersectedWalls = new ArrayList<Integer>(); 
    for (int p = 0; p < sortedEndPoints.size(); p ++){
        intersectedWalls.clear(); 
        //Adds walls already known to be associated with selected endpoints
        for (int i = 0; i < sortedEndPoints.get(p).indices.size(); i ++) {
          intersectedWalls.add(sortedEndPoints.get(p).indices.get(i));
          walls.get(sortedEndPoints.get(p).indices.get(i)).intersect = sortedEndPoints.get(p).location; 
          walls.get(sortedEndPoints.get(p).indices.get(i)).sourceDistance(source, sortedEndPoints.get(p).location); 
          
        }
        
        //looks for wall intersections that aren't already at endpoints
          for (int w = 0; w < walls.size(); w ++) {
            boolean duplicate = false; 
            for (int i = 0; i < intersectedWalls.size(); i ++) {
              if (intersectedWalls.get(i) == w) {
                duplicate = true; 
                break; 
              } 
             }
          
            if (duplicate == false) {
              if (rayLineIntersect (walls.get(w), source, sortedEndPoints.get(p))) {
                intersectedWalls.add(walls.get(w).index); 
              }
             }  
           
        }
        
        
        //deletes extra points
        ArrayList<Integer> toRemove = new ArrayList <Integer>(); 
        toRemove.clear(); 
        for (int i = 0; i < intersectedWalls.size(); i ++) {
          for (int w = 0; w < walls.size(); w ++) {
            if (lineIntersect(walls.get(intersectedWalls.get(i)).intersect, walls.get(w), source)) {
              toRemove.add(intersectedWalls.get(i));  
            } 
          }
        } 
   
        for (int i = 0; i < toRemove.size(); i ++) {
          intersectedWalls.remove(toRemove.get(i)); 
        }

        ArrayList<PVector> toAddtoLOS = new ArrayList<PVector>(); 
          toAddtoLOS.clear();
        for (int w = 0; w < intersectedWalls.size(); w ++) {
          
          toAddtoLOS.add(walls.get(intersectedWalls.get(w)).intersect); 
        }  
        LineOfSight.add(toAddtoLOS);    
  }
  
    return LineOfSight; 
  }

  boolean rayLineIntersect (Wall wall, PVector source, Endpoint point) {
    float x1 = wall.begin.x; 
    float y1 = wall.begin.y; 
    float x2 = wall.end.x; 
    float y2 = wall.end.y; 
    
    float x3 = source.x; 
    float y3 = source.y; 
    
    PVector dir = new PVector (point.location.x - x3, point.location.y  - y3); 
    dir.setMag(width + height); 
    float x4 = source.x + dir.x; 
    float y4 = source.y + dir.y; 
    
    float a1 = y2 - y1; 
    float b1 = x1 - x2; 
    float c1 = a1*x1 + b1*y1; 
 
    float a2 = y4 - y3; 
    float b2 = x3 - x4; 
    float c2 = a2*x3 + b2*y3; 
 
    float det = a1 * b2 - a2 *  b1;    
    boolean over = false; 
    if (det == 0) {
      //do nothing 
    } else { 
      float tolerance = 0.01; 
      float x = (b2 * c1 - b1 * c2)/det; 
      float y = (a1 * c2 - a2 * c1)/det;
  
      
      if (x >= min (x1, x2) - tolerance && x <= max(x1, x2) + tolerance && 
          x >= min(x3, x4) -tolerance && x <= max(x3, x4) +tolerance &&
          y >= min(y1, y2) -tolerance && y <= max(y1, y2) +tolerance &&
          y >= min(y3, y4) -tolerance && y <= max(y3, y4) +tolerance ){
            over =true; 
            wall.setIntersect(new PVector (x, y)); 
            wall.distance = sqrt(sq(x - source.x) + sq(y - source.y)); 
          }
      
      
      
    }
    
    return over; 
    
    
  }
  
  //helper function for sweep, determines if a line of sight crosses over a wall or a building
  boolean lineIntersect(PVector intersect, Wall wall, PVector source) {
    boolean over = false; 
    
    float x1 = wall.begin.x; 
    float y1 = wall.begin.y; 
    float x2 = wall.end.x; 
    float y2 = wall.end.y; 
    
    float x3 = source.x; 
    float y3 = source.y; 
    
    float x4 = intersect.x; 
    float y4 = intersect.y; 
    
    float a1 = y2 - y1; 
    float b1 = x1 - x2; 
    float c1 = a1 * x1 + b1 * y1; 
    
    float a2 = y4 - y3;
    float b2 = x3 - x4; 
    float c2 = a2*x3 + b2*y3; 
    
    float det = a1*b2 - a2*b1; 
    if (det == 0) {
      //do nothing
    } else {
      float x = (b2 * c1 - b1 * c2)/det; 
      float y = (a1 * c2 - a2 * c1)/det; 
      float tolerance = 0.001; 
      if (abs (x - wall.begin.x) > tolerance && abs (x - wall.end.x) > tolerance && abs (y - wall.begin.y) > tolerance && abs (y - wall.end.y) > tolerance && abs (x - intersect.x) > tolerance && abs (y - intersect.y) > tolerance &&
          x >= min(x1, x2) +tolerance && x <= max(x1, x2) -tolerance && 
          x >= min(x3, x4) +tolerance && x <= max(x3, x4) -tolerance &&
          y >= min(y1, y2) +tolerance && y <= max(y1, y2) -tolerance &&
          y >= min(y3, y4) +tolerance && y <= max(y3, y4) -tolerance) {
          over = true; 
      }
    }
    
    return over; 
  }
  
  //determines where the shadow lies, given Line Of Sight
  ArrayList<PVector> getShadows (ArrayList<ArrayList<PVector>> LineOfSight, ArrayList<Endpoint> endPoints, PVector source) {    
    
    
    ArrayList<PVector> sh = new ArrayList<PVector> (); 
    sh.clear(); 
    
    for (int i = 0; i < endPoints.size(); i ++) {
            boolean dup = false; 
            for (int j = 0; j < LineOfSight.size(); j++) {
            for (int k = 0; k < LineOfSight.get(j).size(); k++) {
            if (LineOfSight.get(j).get(k).x == endPoints.get(i).location.x && LineOfSight.get(j).get(k).y == endPoints.get(i).location.y) {
              dup = true; 
            }
          
            }
          }
          
          if (!dup) {
            sh.add(endPoints.get(i).location); 
            
          }
          
        }
    
    int size = LineOfSight.size(); 
    for (int i = 0; i < LineOfSight.size(); i++) {
      float maxDist = 0; 
      PVector farthestPoint = new PVector (); 
      for (int j =0; j < LineOfSight.get(i).size(); j++) {
       float dist = sqrt(sq(LineOfSight.get(i).get(j).x - source.x) + sq(LineOfSight.get(i).get(j).y - source.y)); 
       if (dist > maxDist) {
         maxDist = dist; 
         farthestPoint = LineOfSight.get(i).get(j); 
       }
       
      }
     float tolerance = 0.1;
       if (abs(farthestPoint.x - border) < tolerance || abs(farthestPoint.x - ( width - border)) < tolerance || abs(farthestPoint.y - border) < tolerance || abs(farthestPoint.y - (height - border)) < tolerance) {
       } else { 
         sh.add(farthestPoint);   
         if (i == 0) {
           for (PVector p: LineOfSight.get(size - 1)) {
             sh.add(p); 
           }
         } else {
           for (PVector p: LineOfSight.get(i - 1)) {
              sh.add(p); 
           } 
         }
          for (PVector v: LineOfSight.get((i + 1)%size)) {
            sh.add(v); 
          }
          
    
       }       
    }
    
    return sh; 
  }
  
}




class Endpoint {
  PVector location; 
  float angle, distance; 
  ArrayList<Integer> indices; 
  
  Endpoint(PVector location, int index) {
    this.location = new PVector(); 
    this.location = location; 
    
    indices = new ArrayList<Integer>(); 
    indices.add (index); 
    
    angle = 0; 
  }
  
  void addIndex (int index) {
    boolean duplicate = false; 
    for (int i = 0; i < indices.size(); i ++) {
      if (index == indices.get(i)) {
        duplicate = true; 
        break; 
      }
    }
    if (!duplicate) {
      indices.add(index); 
    }
  }
    
  void sourceangle(PVector source) {
    angle = atan( (location.x - source.x)/(location.y - source.y) );
    angle += 0.5*PI; 
    angle = PI - angle; 
    if ((location.y - source.y) > 0) { 
      angle += PI; 
    } 
    
  }
  
  void display() {
    fill(#FF0000); 
    ellipse (light.x, light.y, 10, 10);
  }
}


class Wall {
  PVector begin; 
  PVector end; 
  int index; 
  PVector intersect; 
  float avgDistance, closestDistance, distance; 
  
  Wall (PVector begin, PVector end, int index) {
    this.begin = begin; 
    this.end = end; 
    this.index = index; 
  }
  
  void setIntersect (PVector intersect) {
     this.intersect = intersect; 
  }
  
  void sourceClosestDistance(PVector source) {
     float deltaX = end.x - begin.x; 
     float deltaY = end.y - begin.y; 
     float num = abs(deltaY*(source.x) - deltaX*(source.y) + (end.x * begin.y) - (end.y * begin.x)); 
     float den = sqrt (sq(deltaY) + sq(deltaX)); 
     closestDistance = num/den; 
  }
 
  void sourceAvgDistance (PVector source) {
    float avgX = 0.5 * (begin.x + end.x); 
    float avgY = 0.5 * (begin.y + end.y); 
    avgDistance = sqrt(sq(avgX - source.x) +  sq(avgY - source.y)); 
  }
  
  void sourceDistance(PVector source, PVector point) {
    distance = sqrt(sq(point.x - source.x) + sq(point.y - source.y)); 
  } 
  
  void display() {
    stroke (200);
    fill (200); 
    line (begin.x, begin.y, end.x, end.y); 
  }
  
}
