//CAPTURA VIDEO//
import processing.video.*;
Capture video;
int camPixels;
PImage antesPixels, imagenDiferencia;
boolean yaTomoReferencia;
//CAPTURA VIDEO//
// SENSADO
// el algoritmo saca un promedio de color
// si su diferencia con el color de referencia es mayor
// que limiteDiferencia, lo dibuja y ademas lo cuenta en presenceSum
int limiteDiferencia = 30;
int limitePresencia = 25000000;
boolean hayPresencia = false;
boolean debug = false;
Mover m;
ArrayList<Mover> movers;
int cuantas = 40;
PImage fondo;
PVector mov = new PVector();

void setup() {
  size(1920, 1080);
  hint(ENABLE_DEPTH_SORT);
  inicializaVideo();
  fondo = loadImage ("fondo.png");
  movers = new ArrayList<Mover>();
  for (int i = 0; i < cuantas; i++) {
    movers.add(new Mover());
  }
}
void draw() {
  background(0);
  procesaVideo();  
  image(fondo, 0, 0, width, height);
  dibujaParticulas();
}
void keyReleased() {
  if (key == 'd' || key == 'D') debug = !debug;
  else if (key == 't' || key == 'T') yaTomoReferencia = false;
}

// Articula movimiento interno de la partícula con un movimiento externo
void dibujaParticulas() {
  
  mov.x = sin(millis()/1000.0)*900 + width/2;
  
  if (hayPresencia==false) {
    mov.y = sin(millis()/500.0)*300 + 300;
  } else {
    int bajar = 4;
    mov.y = mov.y + bajar;
    println("HAY ALGUIEN");
  }
  
  if (debug) ellipse(mov.x, mov.y, 10, 10);
  for (Mover m : movers) {  
    m.arrive(mov);        // Update the location
    m.update();
    m.display();          // Display the Mover
    m.separate(movers);   //if (mov.x < height/4)
  }
}

void tomarReferencia() {
  antesPixels.loadPixels();
  for (int i = 0; i < camPixels; i++) {
    antesPixels.pixels[i] = video.pixels[i];
  }
  antesPixels.updatePixels();
}

void procesaVideo() {
  if (video.available()) {
    // Leer nuevo frame de video
    video.read(); 
    // Hacer disponibles los pixels del video
    video.loadPixels();
    if (!yaTomoReferencia) {
      tomarReferencia();
      yaTomoReferencia = true;
    }
    sustraccionFondo();
  }
  // Dibuja el resultado
  if (debug) { // si se necesita verificar el contenido de las imagenes
    image(imagenDiferencia, 0, 0, width/2, height/2);
    image(antesPixels, width/2, 0, width/2, height/2);
    image(video, width/2, height/2, width/2, height/2);
  } else { // de lo contrario imagen de fondo camara
    image(imagenDiferencia, 0, 0);
  }
}

void sustraccionFondo() {
  int presenceSum = 0;
  // Diferencia entre el frame actual y el fondo almacenado
  // Límite para comparar si el cambio entre las dos imágenes es mayor a...
  imagenDiferencia.loadPixels();
  // Para cada pixel de video de la cámara, tomar el color actual y el anterior de ese pixel
  for (int i = 0; i < camPixels; i++) { 
    color currentColor = video.pixels[i];
    color backgroundColor = antesPixels.pixels[i];
    // Extraer los colores de los píxeles del frame actual
    int currentR = (currentColor >> 16) & 0xFF;
    int currentG = (currentColor >> 8) & 0xFF;
    int currentB = currentColor & 0xFF;
    // Extraer los colores de los píxeles del fondo
    int backgroundR = (backgroundColor >> 16) & 0xFF;
    int backgroundG = (backgroundColor >> 8) & 0xFF;
    int backgroundB = backgroundColor & 0xFF;
    // Computar la diferencia entre los colores
    int diffR = abs(currentR - backgroundR);
    int diffG = abs(currentG - backgroundG);
    int diffB = abs(currentB - backgroundB);
    float promedio = (diffR + diffG + diffB)/3.0;
    // si el pixel es diferente dibuja el mismo pixel
    if (promedio > limiteDiferencia) imagenDiferencia.pixels[i] = currentColor;
    // de lo contrario negro
    else imagenDiferencia.pixels[i] = 0;
    // Sumar las diferencias a la cuenta
    presenceSum += promedio;
  }
  imagenDiferencia.updatePixels();
  println(presenceSum);
  if (presenceSum > limitePresencia) hayPresencia = true;
  else hayPresencia = false;
}

void inicializaVideo() {
  String[] cameras = Capture.list();
  printArray(cameras);
  video = new Capture(this, 1920, 1080, cameras[57]);
  // Iniciar captura
  video.start();
  // Almacenar píxeles de la cámara en variable camPixels
  camPixels = video.width * video.height;
  // Almacenar la imagen el fondo que servirá de referencia en una PImage
  antesPixels = new PImage (video.width, video.height);
  imagenDiferencia = new PImage (video.width, video.height);
  yaTomoReferencia = false;
}