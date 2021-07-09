import netP5.*;
import oscP5.*;
import codeanticode.syphon.*;
import de.looksgood.ani.*;
import processing.video.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

float radius = 60;
float heightHex = sqrt(3) * radius;
float space = 1.4;
float offSet = heightHex /2;
Hex[][] hex = new Hex[30][30]; // 30 x 30 Feld
  

// das Hexagon
class Hex{
  float x;
  float y;
  float z=0;
  Ani hexAni;
  
  Ani hexAniRot;
  Ani hexAni2;
  float movingR;
  float radius;
  boolean home = false;
  float angle = 0;
  float rotEnd = 60;
  PShape s;
  
  Hex(float xi,float yi,float gs) {
    radius = gs;
    movingR = gs;
    x=xi;
    y=yi;
    // das Hexagon wird als Shape im Hex Object/Class erzeugt
    s = createShape();
    s.beginShape();
    s.strokeCap(ROUND);
    s.strokeJoin(MITER);
    s.fill(color(0,170,250,0.9));
    s.vertex(- radius,  - sqrt(3) * radius); // sqrt(3) * radius = höhe des Hexagons
    s.vertex( radius,  - sqrt(3) * radius);
    s.vertex(2 * radius, 0);  // 2* radius = länge
    s.vertex( radius,   sqrt(3) * radius);
    s.vertex( - radius, sqrt(3) * radius);
    s.vertex(-2 * radius, 0);
    s.vertex( - radius,  - sqrt(3) * radius);
    s.endShape(CLOSE);
    s.setFill(color(0,170,250,0.9)); // RotGrünBlau 0 - 255 Alpha 0.0 - 1.0
    s.setStroke(color(180,180,250,0.9));
    s.setStrokeWeight(3);
  }
 
  void draw(){
    pushMatrix(); // push und popMatrix klammern eine XYZAchse in der Befehlskette von Transformation  … P3D magic
      translate(x * space , (y + offSet )* space ,z);
      rotateZ(angle*PI/180);
      shape(s,0,0);
      if(hexAniRot != null){ 
        if(hexAniRot.isEnded()){
           s.setStroke(color(180,180,250,0.7));
           s.setStrokeWeight(3);
           s.setFill(color(0,170,250,0.9));
       }
     } 
     if(hexAni2 != null) if(hexAni2.isEnded()) { //Rotation zu Ende beim close … I am home!
       home = false; hexAni2 = null;         
     }
   popMatrix(); 
  }
  
  // Animation für neue Z-Position
  void  doMoveZ(float newZPos){
    // Hex wird transparent
    s.setStroke(color(0,160,220));
    s.setStrokeWeight(10);
    s.setFill(color(0,0,0,1));
    // rotation nach Weglänge berechen
    float spin = 1500; // Wert ist zu speilen 
    
    int twist;
    if(newZPos>z) twist = int(floor(newZPos-z)/spin); else twist = int(floor(z - newZPos)/spin);
    hexAni =  Ani.to(this, 9.0, "z",newZPos, Ani.EXPO_IN_OUT);
    rotEnd *= -1;
    hexAniRot =  Ani.to(this, 8.6, "angle", rotEnd * twist , Ani.LINEAR);
    hexAni.setPlayMode(Ani.FORWARD);
    hexAniRot.start();
    hexAni.start();
  }
  
  // Animation für Close
  void  goHome(){
    home = true;
    if( hexAni != null ) {
      hexAni.pause();
      hexAni = null;
    }
    hexAni2 = Ani.to(this, 1.0, "z",0, Ani.EXPO_IN_OUT);
    hexAniRot =  Ani.to(this, 1.0, "angle", 0 , Ani.ELASTIC_IN_OUT);
    hexAni2.setPlayMode(Ani.FORWARD);
    hexAni2.start();
  }
  
  // Animation für aus ein an der 
  void  xplode(){
    home = true;
    if( hexAni != null ) {hexAni.pause(); hexAni = null;} // delete old ani
    hexAni2 = Ani.to(this, 1.0, "z",4000-random(8000), Ani.EXPO_IN_OUT); // +-4000 Zufall
    rotEnd *= -1;
    hexAniRot =  Ani.to(this, 1.0, "angle",rotEnd * 3, Ani.ELASTIC_IN_OUT);
    hexAni2.setPlayMode(Ani.FORWARD);
    hexAni2.start();
  }
}

void setup(){
  size(1025,768,P3D);
  frameRate(30);
  background(0);
  float x = 0;
  float y = 0; 
  
  oscP5 = new OscP5(this,6666);
  Ani.init(this); // Ani init ist wichtig!!!
  
  for(int ix = 0; ix < hex.length; ix++){
    y = 0 ;
    x += ( 3 * radius);
    for(int iy = 0; iy < hex[0].length; iy ++ ){
      y += heightHex*2;
      hex[ix][iy] = new Hex(x-hex.length*space*radius,y-hex[0].length*space*radius,radius);      
    }
  } 
}

// get triggerd on key "c" and OCS "/close"
void home(){
  for(int ix = 0; ix < hex.length; ix++){
    for(int iy = 0; iy < hex[0].length; iy ++ ){
        hex[ix][iy].goHome(); 
    }
  }
}

// get triggerd on key "cx" and OCS "/xplode"
void xplode(){
  for(int ix = 0; ix < hex.length; ix++){
    for(int iy = 0; iy < hex[0].length; iy ++ ){
        hex[ix][iy].xplode(); 
    }
  }
}

boolean doChange(float lotto, float win){
  if(random(lotto) >lotto - win) return true; else return false;
}

void draw(){
  offSet = heightHex/2 ;
  clear();
  background(0);
  blendMode(SCREEN);
  lightFalloff(1.5, 0.01, 0.0);
  
  pushMatrix();
    noClip();
    lights();
    lightSpecular(255, 255, 255);
     // Camera move
    translate(0,0,-500);
    rotateX(frameCount*0.008);
    rotateY(frameCount*0.006);
    rotateZ(frameCount*0.02);
    
    float newZ;
    float distanceZ = 80;
    int stopPoses = 70;
   
    for(int x = 0; x < hex.length; x++){
      for(int y = 0; y < hex[0].length; y ++){
        if(doChange(1000,2) && !hex[x][y].home){ // Neu position und nicht am heinmfahren
          if (hex[x][y].z <= 0) // Wenn oben dann nach unten / bei 0 rauf (home)
              newZ = int(random(stopPoses)) * distanceZ; //int(random(stopPos)) = 70 Positionen z mit Abstand 80
          else newZ = int(random (stopPoses)) * distanceZ*-1;
          hex[x][y].doMoveZ(newZ);
        }
        hex[x][y].draw();
      }
      offSet *=-1;
   }  
 popMatrix(); 
 if(keyPressed){
   switch(key){
     case 'c' : home();
       break;
     case 'x' : xplode();
       break;
   }   
 }
}

//OSC
void oscEvent(OscMessage theOscMessage) {
 if(theOscMessage.checkAddrPattern("/xplode")) xplode();
 if(theOscMessage.checkAddrPattern("/close")) home();
}
