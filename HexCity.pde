import netP5.*;
import oscP5.*;
import codeanticode.syphon.*;
import de.looksgood.ani.*;
import processing.video.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

float radius = 40;
float heightHex = sqrt(3) * radius;
float space = 1.2;
float offSet = heightHex /2;
Hex[] hex = new Hex[200]; // 30 x 30 Feld
SyphonServer server;
// https://www.redblobgames.com/grids/hexagons/
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
        if(hexAniRot.isEnded()){ // Stehend sind die Hexagons gefüllt
           s.setStroke(color(180,180,250,0.7));
           s.setStrokeWeight(3);
           s.setFill(color(0,170,250,0.9)); // helles leichtes aber durchlässiges(aplha/opacity) grünblau
       }
     } 
     if(hexAni2 != null) if(hexAni2.isEnded()) { // Animation zu Ende beim close … I am home!
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
    float spin = 1500; // Wert ist zu spielen = Länge/Spin = Anzahl der 60° Drehungen = twist 
    
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
  size(640,480,P3D);
  frameRate(30);
  background(0);
  float x = 0;
  float y = 0;
  float rField = radius * sqrt(3) * 2;
  float angleField = 60;
  float angleBuild = 0;
  int count = 6;
  float offset = 30;
   server = new SyphonServer(this, "Processing HexCity");
  oscP5 = new OscP5(this,6666);
  Ani.init(this); // Ani init ist wichtig!!!
  hex[0] = new Hex(x,y,radius);
  for(int i = 1; i < hex.length; i++){ 
      x = (float)( rField * Math.cos((angleBuild+offset) * PI / 180));
      y = (float)( rField * Math.sin((angleBuild+offset) * PI / 180));
      hex[i] = new Hex(x,y,radius);
      if(i>=count){
        print("count" + count + " rField:" + rField + " angel" + angleField );
        count *=2;
        rField += radius * sqrt(3) * 2;
        angleField = 360/count;
        angleBuild = 0;
        offset *= -1;
      }else  angleBuild += angleField;
    }
  } 

// get triggerd on key "c" and OCS "/close"
void home(){
  for(int i = 0; i < hex.length; i++){
   
        hex[i].goHome(); 
    }
}

// get triggerd on key "cx" and OCS "/xplode"
void xplode(){
  for(int i = 0; i < hex.length; i++){
        hex[i].xplode(); 
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
  smooth();
  
  pushMatrix();
    lightFalloff(1.0, 0.05, 0.0);
    clip(-width,-height,width*2,height*2);
    lights();
    lightSpecular(155, 155, 155);
     // Camera move
    translate(0,0,-500);
    rotateX(frameCount*0.008);
    rotateY(frameCount*0.006);
    rotateZ(frameCount*0.02);
    
    float newZ;
    float distanceZ = 80;
    int stopPoses = 70;
   
    for(int i = 0; i < hex.length; i++){
  
      /*if(doChange(1000,2) && !hex[i].home){ // Neu position und nicht am heinmfahren
          if (hex[i].z <= 0) // Wenn oben dann nach unten / bei 0 rauf (home)
              newZ = int(random(stopPoses)) * distanceZ; //int(random(stopPos)) = 70 Positionen z mit Abstand 80
          else newZ = int(random (stopPoses)) * distanceZ*-1;
          hex[i].doMoveZ(newZ);
        }*/
        hex[i].draw();
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
 server.sendScreen();
}

//OSC
void oscEvent(OscMessage theOscMessage) {
 if(theOscMessage.checkAddrPattern("/xplode")) xplode();
 if(theOscMessage.checkAddrPattern("/close")) home();
}
