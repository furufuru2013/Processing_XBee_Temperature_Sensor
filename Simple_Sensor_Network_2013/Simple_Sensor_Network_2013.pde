/*
 * Simple_Sensor_Network_2013 - 2013/01/20 by @f
 *
 */

import processing.serial.*;
import java.util.concurrent.*;

import com.rapplogic.xbee.api.ApiId;
import com.rapplogic.xbee.api.PacketListener;
import com.rapplogic.xbee.api.XBee;
import com.rapplogic.xbee.api.XBeeResponse;
import com.rapplogic.xbee.api.zigbee.ZNetRxIoSampleResponse;

String version = "0.01";

// *** REPLACE WITH THE SERIAL PORT (COM PORT) FOR YOUR LOCAL XBEE ***
String mySerialPort = "COM11";

// create and initialize a new xbee object
XBee xbee = new XBee();
//Logger log = Logger.getLogger(XBeePacketParser.class);
static final boolean dispThermometer = true;

int error=0;

// make an array list of thermometer objects for display
ArrayList thermometers = new ArrayList();
// create a font for display
PFont font;

// Support variable sensor by @f
ArrayList sensorinfoes = new ArrayList();

void setup() {
  // setup sensor infomation
  sensorinfoes.add(new SensorInfo(0, "00:13:a2:00:40:86:bb:40", "TMP36GT9Z", "XB24-Z7CIT-004", "JS-room", 1.2, 0.5));
  sensorinfoes.add(new SensorInfo(1, "00:13:a2:00:40:89:1b:3f", "TMP36GT9Z", "XB24-Z7CIT-004", "outside", 1.2, 0.5));
  sensorinfoes.add(new SensorInfo(5, "00:13:a2:00:40:99:97:92", "LM60BIZ",   "XB24-Z7PIT-004", "study", 1.2, 0.33));
  sensorinfoes.add(new SensorInfo(6, "00:13:a2:00:40:99:98:60", "LM60BIZ",   "XB24-Z7CIT-004", "desktop", 1.2, 0.33));
/*
24.4C  "LM60BIZ":488 "TMP36GT9Z":637
488 / 1023 * 1.2 - b = 0.244
b = 488 / 1023 * 1.2 - 0.244 = 0.572 - 0.244 = 0.33
*/

  if (dispThermometer) {
    size(800, 600); // screen size
    smooth(); // anti-aliasing for graphic display
  
    // You’ll need to generate a font before you can run this sketch.
    // Click the Tools menu and choose Create Font. Click Sans Serif,
    // choose a size of 10, and click OK.
//    font =  loadFont("SansSerif-10.vlw");
//    textFont(font); // use the font for text
  }
  
  // The log4j.properties file is required by the xbee api library, and 
  // needs to be in your data folder. You can find this file in the xbee
  // api library you downloaded earlier
  PropertyConfigurator.configure(dataPath("")+"\\log4j.properties");
  // Print a list in case the selected one doesn't work out
  println("Available serial ports:");
  println(Serial.list());
  try {
    // opens your serial port defined above, at 9600 baud
    xbee.open(mySerialPort, 9600);
  }
  catch (XBeeException e) {
    println("** Error opening XBee port: " + e + " **");
    println("Is your XBee plugged in to your computer?");
    println("Did you set your COM port in the code near line 20?");
    error=1;
  }
}

// draw loop executes continuously
void draw() {
  background(224); // draw a light gray background
  // report any serial port problems in the main window
  if (error == 1) {
    fill(0);
    text("** Error opening XBee port: **\n"+
      "Is your XBee plugged in to your computer?\n" +
      "Did you set your COM port in the code near line 20?", width/3, height/2);
  }
  SensorData data = new SensorData(); // create a data object
  data = getData(); // put data into the data object
  //data = getSimulatedData(); // uncomment this to use random data for testing

  // check that actual data came in:
  if (data.value >=0 && data.address != null) { 

    // check to see if a thermometer object already exists for this sensor
    boolean foundIt = false;
    int i;
    
    if (dispThermometer) {
      for (i=0; i <thermometers.size(); i++) {
        if ( ((Thermometer) thermometers.get(i)).address.equals(data.address) ) {
          foundIt = true;
          break;
        }
      }
    }
    
    // process the data value into a Celsius temperature reading for
    // LM335 with a 1/3 voltage divider
    //   (value as a ratio of 1023 times max ADC voltage times 
    //    3 (voltage divider value) divided by 10mV per degree
    //    minus zero Celsius in Kevin)

    float ratio = 1.2, offset = 0.5;
    int  sensor_id = (-1);
    for (int k = 0; k < sensorinfoes.size(); k++) {
        if ( ((SensorInfo)sensorinfoes.get(k)).address.equals(data.address) ) {
          ratio = ((SensorInfo)sensorinfoes.get(k)).ratio;
          offset =  ((SensorInfo)sensorinfoes.get(k)).offset;
          sensor_id = k;
          break;
        }
    }
    float temperatureCelsius = (data.value/1023.0*ratio-offset)*100.0;
    println(" temp: " + round(temperatureCelsius*10.0)/10.0 + "C");

//    println(" Value: " + data.value);
   
     if (dispThermometer) {
      // update the thermometer if it exists, otherwise create a new one
      if (foundIt) {
        ((Thermometer) thermometers.get(i)).temp = temperatureCelsius;
      }
      else if (thermometers.size() < 10) {
        thermometers.add(new Thermometer(data.address,35,450,
        (thermometers.size()) * 75 + 40, 20));
        ((Thermometer) thermometers.get(i)).temp = temperatureCelsius;
      }
  
      ((Thermometer) thermometers.get(i)).sensor_id = sensor_id;  // add by @f
      
      // draw the thermometers on the screen
      for (int j =0; j<thermometers.size(); j++) {
        ((Thermometer) thermometers.get(j)).render();
      }
    }
  }
} // end of draw loop

// defines the data object
class SensorData {
  int value;
  String address;
}

// defines the thermometer objects
class Thermometer {
  int sizeX, sizeY, posX, posY;
  int maxTemp = 40; // max of scale in degrees Celsius
  int minTemp = -10; // min of scale in degress Celcisu
  float temp; // stores the temperature locally
  String address; // stores the address locally
  int    sensor_id;  // add by @f

  Thermometer(String _address, int _sizeX, int _sizeY, 
  int _posX, int _posY) { // initialize thermometer object
    address = _address;
    sizeX = _sizeX;
    sizeY = _sizeY;
    posX = _posX;
    posY = _posY;
  }

  void render() { // draw thermometer on screen
    noStroke(); // remove shape edges
    ellipseMode(CENTER); // center bulb
    float bulbSize = sizeX + (sizeX * 0.5); // determine bulb size
    int stemSize = 30; // stem augments fixed red bulb 
    // to help separate it from moving mercury
    // limit display to range
    float displayTemp = round( temp );
    // float displayTemp = round( temp * 10.0) / 10.0;
    if (temp > maxTemp) {
      displayTemp = maxTemp + 1;
    }
    if ((int)temp < minTemp) {
      displayTemp = minTemp;
    }
    // size for variable red area:
    float mercury = ( 1 - ( (displayTemp-minTemp) / (maxTemp-minTemp) )); 
    // draw edges of objects in black
    fill(0); 
    rect(posX-3,posY-3,sizeX+5,sizeY+5); 
    ellipse(posX+sizeX/2,posY+sizeY+stemSize, bulbSize+4,bulbSize+4);
    rect(posX-3, posY+sizeY, sizeX+5,stemSize+5);
    // draw grey mercury background
    fill(64); 
    rect(posX,posY,sizeX,sizeY);
    // draw red areas
    fill(255,16,16);

    // draw mercury area:
    rect(posX,posY+(sizeY * mercury), 
    sizeX, sizeY-(sizeY * mercury));

    // draw stem area:
    rect(posX, posY+sizeY, sizeX,stemSize); 

    // draw red bulb:
    ellipse(posX+sizeX/2,posY+sizeY + stemSize, bulbSize,bulbSize); 

    // show text
    textAlign(LEFT);
    fill(0);
    textSize(10);

    // show sensor address:
    text(address, posX-10, posY + sizeY + bulbSize + stemSize +12, 65, 40);
    
    // show sensor number by @f
    textAlign(CENTER);
    text("#" + ((SensorInfo)sensorinfoes.get(sensor_id)).id
                                                        , posX-12, posY + sizeY + bulbSize + 6, 65, 40);
    text(((SensorInfo)sensorinfoes.get(sensor_id)).place, posX-12, posY + sizeY + bulbSize + 16, 65, 40);
    text("[" + ((SensorInfo)sensorinfoes.get(sensor_id)).sensor_name + "]"
                                                        , posX-12, posY + sizeY + bulbSize + 26, 65, 40);
    // show maximum temperature: 
    textAlign(LEFT);
    text(maxTemp + "˚C", posX+sizeX + 5, posY); 

    // show minimum temperature:
    text(minTemp + "˚C", posX+sizeX + 5, posY + sizeY); 

    // show temperature:
    text(round(temp * 10.0) / 10.0 + " ˚C", posX+2,posY+(sizeY * mercury+ 14));
  }
}

// used only if getSimulatedData is uncommented in draw loop
//
SensorData getSimulatedData() {
  SensorData data = new SensorData();
  int value = int(random(750,890));
  String address = "00:13:A2:00:12:34:AB:C" + str( round(random(0,9)) );
  data.value = value;
  data.address = address;
  delay(200);
  return data;
}


// queries the XBee for incoming I/O data frames 
// and parses them into a data object
SensorData getData() {

  SensorData data = new SensorData();
  int value = -1;      // returns an impossible value if there's an error
  String address = ""; // returns a null value if there's an error

  try {      
    // we wait here until a packet is received.
    XBeeResponse response = xbee.getResponse();
    // uncomment next line for additional debugging information
    //println("Received response " + response.toString()); 

    // check that this frame is a valid I/O sample, then parse it as such
    if (response.getApiId() == ApiId.ZNET_IO_SAMPLE_RESPONSE 
      && !response.isError()) {
      ZNetRxIoSampleResponse ioSample = 
        (ZNetRxIoSampleResponse)(XBeeResponse) response;

      // get the sender's 64-bit address
      int[] addressArray = ioSample.getRemoteAddress64().getAddress();
      // parse the address int array into a formatted string
      String[] hexAddress = new String[addressArray.length];
      for (int i=0; i<addressArray.length;i++) {
        // format each address byte with leading zeros:
        hexAddress[i] = String.format("%02x", addressArray[i]);
      }

      // join the array together with colons for readability:
      String senderAddress = join(hexAddress, ":"); 
      print("Sender address: " + senderAddress);
      data.address = senderAddress;
      // get the value of the first input pin
      value = ioSample.getAnalog1();
      print(" analog value: " + value ); 
      data.value = value;
    }
    else if (!response.isError()) {
      println("Got error in data frame");
    }
    else {
      println("Got non-i/o data frame");
    }
  }
  catch (XBeeException e) {
    println("Error receiving response: " + e);
  }
  return data; // sends the data back to the calling function
}

//----------------------------------------------------------------------------
// SensorInfo  by @f
//----------------------------------------------------------------------------
class SensorInfo {
  int    id;
  String  address;
  String  sensor_name, xbee_name, place;
  float    ratio, offset;

  // Constructor
  SensorInfo(int _id, String _address, String _sensor_name, String _xbee_name, String _place, float _ratio, float _offset) {
    id = _id;
    address = _address;
    sensor_name = _sensor_name;
    xbee_name = _xbee_name;
    place = _place;
    ratio = _ratio;
    offset = _offset;
  }
  
}

