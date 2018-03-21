// Design: nodemcu_fpga_server
// Description: 
// Author: German Cano Quiveu <germancq@dte.us.es>
// Copyright Universidad de Sevilla, Spain

#include <ESP8266WebServer.h>
#include <ESP8266WiFi.h> 
#include<SPI.h>
#include "base64.hpp" //https://github.com/Densaugeo/base64_arduino

ESP8266WebServer server(3000); //creating the server at port 3000

const char* ssid = ""; // Rellena con el nombre de tu red WiFi
const char* password = ""; // Rellena con la contraseña de tu red WiFi

//sclk:D5 
//miso:D6
//mosi:D7
//cs:D8

IPAddress ip(192, 168, 2, 8);  
IPAddress gateway(192, 168, 2, 1);
IPAddress subnet(255, 255, 255, 0);

const int slaveSelectPin = D8;
const int o_boot_start = D3;
const int o_boot_end = D0;
const int o_boot_comm = D1;
const int i_boot_req_byte = D2;


int interruptCounter = 0;
int n_block = 0;
int total_blocks = 0;
int finished_send = 0;
byte data[512];
byte aux_buffer[1024];
int bytes_sends = 0;
int total_bytes = 0;
int counter_blocks = 0;

void setup() {
  Serial.begin(115200);

  delay(10);
 
  // Conectamos a la red WiFi
 
  Serial.println();
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.config(ip,gateway,subnet);
  WiFi.mode(WIFI_STA); // Modo cliente WiFi
  WiFi.begin(ssid, password);
 
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
 
  Serial.println("");
  Serial.println("WiFi connected"); 
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP()); // Mostramos la IP

  
  
  server.on("/data", handleJSON);
  server.begin();

  //SPI

  pinMode(slaveSelectPin, OUTPUT);
  pinMode(o_boot_start, OUTPUT);
  pinMode(o_boot_end, OUTPUT);
  pinMode(o_boot_comm, OUTPUT);
  pinMode(i_boot_req_byte,INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(i_boot_req_byte), handleInterrupt, FALLING);
  SPI.begin() ;
  SPI.beginTransaction(SPISettings(4000000, MSBFIRST, SPI_MODE0));
  digitalWrite(o_boot_start,LOW);
  digitalWrite(o_boot_comm,LOW);
  digitalWrite(o_boot_end,LOW);
  digitalWrite(slaveSelectPin, LOW);


  interruptCounter = 0;
  
}

void handleInterrupt() {
  cli();
  digitalWrite(slaveSelectPin, LOW);
  SPI.transfer(data[interruptCounter]);
  digitalWrite(slaveSelectPin, HIGH);
  interruptCounter++;
  if(interruptCounter == bytes_send - 1){
    digitalWrite(o_boot_comm,LOW);
  }
  if(interruptCounter >= bytes_sends){
    Serial.print("terminado envio de : ");
    Serial.print(bytes_sends);
    Serial.println(" bytes");
    interruptCounter = 0;
    finished_send = 1;
    detachInterrupt(i_boot_req_byte);
  }
  sei();
}


void handleJSON() {
  digitalWrite(o_boot_start,HIGH);
  digitalWrite(o_boot_comm,LOW);
  total_bytes = server.arg("total_bytes").toInt();
  String encoded_string = server.arg("data");
  encoded_string.getBytes(aux_buffer,encoded_string.length());
  n_block = server.arg("n_block").toInt();
  total_blocks = server.arg("total_blocks").toInt();
  counter_blocks++;
  Serial.print("total_bytes : ");
  Serial.println(total_bytes);
  Serial.print("n_block : ");
  Serial.println(n_block);
  Serial.print("total_blocks : ");
  Serial.println(total_blocks);
  Serial.print("counter_blocks : ");
  Serial.println(counter_blocks);


  
  finished_send = 0;
  //prepara valores para la interrupcion
  //primero enviar n_block
  data[3] = (byte)(n_block);
  data[2] = (byte)(n_block>>8);
  data[1] = (byte)(n_block>>16);
  data[0] = (byte)(n_block>>24);
  bytes_sends = 4;
  digitalWrite(o_boot_comm,HIGH);
  do{delay(10);}while(finished_send == 0);
  digitalWrite(o_boot_comm,LOW);
  Serial.println("terminado envio n_block");
  finished_send = 0;
  attachInterrupt(digitalPinToInterrupt(i_boot_req_byte), handleInterrupt, FALLING);

  //enviar total_bytes
  data[3] = (byte)(total_bytes);
  data[2] = (byte)(total_bytes>>8);
  data[1] = (byte)(total_bytes>>16);
  data[0] = (byte)(total_bytes>>24);
  bytes_sends = 4;
  digitalWrite(o_boot_comm,HIGH);
  do{delay (10);}while(finished_send == 0);
  digitalWrite(o_boot_comm,LOW);
  Serial.println("terminado envio total_bytes");
  finished_send = 0;
  attachInterrupt(digitalPinToInterrupt(i_boot_req_byte), handleInterrupt, FALLING);

  //enviar data
  //data_server.getBytes(data,total_bytes);
  decode_base64(aux_buffer,data);
  bytes_sends = total_bytes;
  digitalWrite(o_boot_comm,HIGH);
  do{delay (10);}while(finished_send == 0);
  digitalWrite(o_boot_comm,LOW);
  Serial.println("terminado envio data");
  finished_send = 0;
  attachInterrupt(digitalPinToInterrupt(i_boot_req_byte), handleInterrupt, FALLING);
  
  
  if(counter_blocks == total_blocks){
    Serial.println("FIN");
    digitalWrite(o_boot_start,LOW);
    delay(100);
    digitalWrite(o_boot_end,HIGH);
    delay(100);
    digitalWrite(o_boot_end,LOW);
    counter_blocks = 0;
  }
  
  server.send(200,"text/plain","Data submitted");
}

void loop() {
  server.handleClient(); //this is required for handling the incoming requests
}
