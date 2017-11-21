import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;  
AudioInput in;
FFT fftLog;
float[] averages;
float[] longAverages;
float levelAverage;



// sound analyzer parameters
float spectrumScale = 2;  // how far the bars move
int numDivPerOctave = 1;   // how many bars
float damping = 0.5;      // how much waveform is smoothed (0-1): 0 = no smoothing
                           // 0 is really twitchy. .99 is very slow
float levelDamping = 0.9;  // damping for sphere
float longDamping = 0.9;

// 3D visualizer parameters
float innerRadius=100;     // inner radius of ring
float sphereRadius = 40;  // radius of sphere
float boxHeight = 10;      // how tall or deep the bars are
float ang = PI/4;             // starting rotation angle
float spinRate = 0.0005; // how fast it spins  - parameter in radians() is in degrees
float offset3D = 0.07;      // adjusts how much depth in the 3D image




float cubeEdge;
int numBalls;
float ballSize;
PGraphics left, right;
int sphereRes;
float avgFrameRate;


void settings() {
  fullScreen(P3D);
}


void setup() {
  avgFrameRate = 0;
  size(1000, 750, P3D);
  left = createGraphics(width, height, P3D);
  right = createGraphics(1000, 750, P3D);
  ang = 0;
  cubeEdge = float(height/2);
  numBalls = 20;
  sphereRes = 20;
  ballSize = 8 ;
  
  minim = new Minim(this);
  in = minim.getLineIn();
  
  // create an FFT object for calculating logarithmically spaced averages
  fftLog = new FFT( in.bufferSize(), in.sampleRate() );
  
  // calculate averages based on a miminum octave width of 22 Hz
  // split each octave into three bands
  // this should result in 30 averages
  fftLog.logAverages( 88, numDivPerOctave );
  averages = new float[fftLog.avgSize()];
  longAverages = new float[fftLog.avgSize()];
  levelAverage = 0;
}

void draw() {
  WindowFunction newWindow = FFT.BARTLETT;
  fftLog.window( newWindow );
  // perform a forward FFT on the samples in jingle's mix buffer
  // note that if jingle were a MONO file, this would be the same as using jingle.left or jingle.right
  fftLog.forward( in.mix );
  // compute the logarithmic averages
  
  // level averages
  levelAverage = levelDamping*levelAverage + (1 - levelDamping)*in.mix.level()/0.3;
  
  for(int i = 0; i < fftLog.avgSize(); i++)
  {
    float barSize = (log( exp(1) + fftLog.getAvg(i))-1);
    averages[i] = (damping*averages[i] + (1 - damping)*barSize);  
    longAverages[i] = (longDamping*longAverages[i] + (1 - longDamping)*barSize);  
    //println(i,averages[i],longAverages[i],averages[i]/longAverages[i]);
  }
  
  float cameraY = height/2.0;
  float fov = mouseX/float(width) * PI/2;
  float cameraZ = cameraY / tan(fov / 2.0);
  float aspect = float(width)/float(height);
  left.beginDraw();
  left.colorMode(HSB);
  left.perspective(fov, aspect, cameraZ/10.0, cameraZ*10.0);
  left.background(0);
  left.spotLight(255, 0, 255, width*2, height, width*3, 0, 0, -1, PI/4, 2);
  left.noStroke();
  left.sphereDetail(sphereRes);
  left.fill(255);
  if( mousePressed ) {
    ang = mouseX/float(height) * 2*PI;
  } else {
    ang = millis()*spinRate;
  }
  damping = mouseY*1.0/width*1.0;
  left.translate(width/2, height/2, 0);
  left.rotateY(-ang);
  left.rotateX(PI/3 + mouseY/float(height) * PI);
  numBalls=fftLog.avgSize();
  for( int i = 0 ; i <numBalls ; i++ ) {
    for( int j = 0 ; j < numBalls ; j++ ) {
      for( int k = 0 ; k < numBalls ; k++ ) {
        float amt = 0.051;
        float hue = 1080*noise(j*amt,k*amt,millis()*0.0001)%360;
        float hue2 = 1080*noise(i*amt,millis()*0.0001)%360;
        left.fill((hue+hue2)%360,255,255);
        float bS = ballSize*averages[i]*averages[j]*averages[k]/(longAverages[i]*longAverages[j]*longAverages[k]);
        float x = (0.5-i/(float(numBalls) - 1))*cubeEdge;
        float y = (0.5-j/(float(numBalls) - 1))*cubeEdge;
        float z = (0.5-k/(float(numBalls) - 1))*cubeEdge;
        left.pushMatrix();
        left.translate( x, y, z );
        left.sphere(bS);
        //left.box(bS,bS,bS);
        left.popMatrix();
      }
    }
  }
  left.endDraw();
  
 
  image(left,0,0,width,height);
  
  avgFrameRate = (avgFrameRate * 19 + frameRate ) / 20;
  if ( ( frameCount % 25 ) == 0 ) {
    println("Framerate: " + avgFrameRate + "   Frame: " + frameCount );
  }
  
}