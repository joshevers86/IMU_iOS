//
//  BLEHandler.swift
//  MarcadoresRehabilitacion
//
//  Created by Jose Navarro Alabarta on 7/3/16.
//  Copyright © 2016 ai2-upv. All rights reserved.
//

import Foundation
import CoreBluetooth
import Darwin

/* https://www.ralfebert.de/tutorials/ios-swift-multipeer-connectivity/
// por aki --> http://code.tutsplus.com/tutorials/ios-7-sdk-core-bluetooth-practical-lesson--mobile-20741
// https://www.raywenderlich.com/52080/introduction-core-bluetooth-building-heart-rate-monitor
// http://alperkayabasi.com/2015/02/13/corebluetooth-cbcentralmanager-tutorial-ios/
// https://github.com/0x7fffffff/Core-Bluetooth-Transfer-Demo/blob/master/Bluetooth/BTLECentralViewController.swift
// https://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
// http://anasimtiaz.com/?p=201
// http://stackoverflow.com/questions/26377615/ble-swift-write-characterisitc
 
 dar permisos a la camara y blue
 https://devzone.nordicsemi.com/question/33704/ble-settings-for-max-data-transfer-speed-to-ios/
https://developer.apple.com/library/content/qa/qa1937/_index.html
 http://stackoverflow.com/questions/39383289/ios-10-gm-release-error-when-submitting-apps-app-attempts-to-access-privacy-sen
*/


/*let batteryServiceUUIDString = CBUUID(string : "0000180F-0000-1000-8000-00805F9B34FB")
let batteryLevelCharacteristicUUIDString = CBUUID(string :"00002A19-0000-1000-8000-00805F9B34FB")*/

let BLEServiceUUID = CBUUID(string : "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
let TXCharacteristicUUID =  CBUUID(string :  "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
let RXCharacteristicUUID = CBUUID(string : "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")



class BLEDiscovery : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    
    fileprivate var centralManager : CBCentralManager!
    fileprivate var peripheralBLE: [CBPeripheral?] = [CBPeripheral?]()
    let data = NSMutableData()
    var tramas : [Int] = [0,0,0,0,0,0,0]
    var nrf51 : [String] =  ["","","","","","",""]
    
    
    var nrf51_1 = String()
    var aux = String()
    var nrf51_2 = String()
    var aux2 = String()
    var nrf51_3 = String()
    var aux3 = String()
    var nrf51_4 = String()
    var aux4 = String()
    var nrf51_5 = String()
    var aux5 = String()
    var nrf51_6 = String()
    var aux6 = String()
    var nrf51_7 = String()
    var aux7 = String()
    
/*****************************************************************************************************************************
******************************************************************************************************************************
******************************************************************************************************************************
*----------------------------------------------------Parte del descubrimiento------------------------------------------------*
******************************************************************************************************************************
******************************************************************************************************************************
*****************************************************************************************************************************/
    
    override init(){
        super.init()
        
        //lanzando el CBCentralManager
        //let centralQueue = dispatch_queue_create("es.upv.ai2", DISPATCH_QUEUE_SERIAL)
        let centralQueue = DispatchQueue(label: "es.upv.ai2", attributes: DispatchQueue.Attributes.concurrent)
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
        //centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /*
    * Funcion para escanear dispositivos BLE, solo son visibles los que correspondan con el Servicio UUID que este dado de
    * alta en el vector BLEServiceUUID.
    */
    func startScanning() {
        if let central = centralManager {
            //primer argumento es para filtrar el escaneo por el servicio a usar
            central.scanForPeripherals(withServices: [BLEServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey : NSNumber(value: false as Bool)])
        }
    }
    
    
    
    /*
    * Funcion para limpiar los dispositivos cuando no este disponible o se resetee la conexion Bluetooth
    */
    func clearDevices() {
        self.peripheralBLE.removeAll()
    }
    
    
    /*
    * Funcion del protocolo BLE con el cual se puede saber el estado actual del BLE cuando se da al boton de escanear
    * si el BLE se encuentra activo, se realizara el descubrimiento de los diferentes BLE disponibles
    */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch (central.state){
        case .poweredOff:
            print("CoreBluetooth BLE hardware is powered off")
            self.clearDevices()
        case .poweredOn:
            print("CoreBluetooth BLE hardware is powered on and ready")
            self.startScanning()
        case .resetting:
            print("CoreBluetooth BLE hardware is resetting")
            self.clearDevices()
        case .unauthorized:
            print("CoreBluetooth BLE state is unauthorized")
        case .unknown:
            print("CoreBluetooth BLE state is unknown")
        case .unsupported:
            print("CoreBluetooth BLE hardware is unsupported on this platform")
        }
    }
    
    /*
    * Funcion del protocolo BLE que permite descubrir los distintos dispositivos mientras se esta escaneando
    */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // si los perifericos no tienen nombre o su nombre es la cadena vacia se descartan
        if ((peripheral.name == nil) || (peripheral.name == "")) {
            return
        }
        
        print("\(peripheral.name!) at \(RSSI)")
        
        self.peripheralBLE.append(peripheral)
        for pble in self.peripheralBLE {
            if  ( pble != peripheral || (pble?.state == CBPeripheralState.disconnected) ){
                
                central.connect(peripheral, options: nil)
                print("Connecting to peripheral \(peripheral)")
            }
        }
    }
    

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager?.stopScan()
        print("Scanning stopped")
        
        
        for pbledel in self.peripheralBLE {
            
            // Clear the data that we may already have
            data.length = 0
            
            // Make sure we get the discovery callbacks
            peripheral.delegate = self
            // Busca solo los servicios que coinciden con el UUID
            
            if (pbledel!.state == CBPeripheralState.connected){
                print("\(pbledel!.name!) is connected")
                //Start Discovering Services for a BLE Device
                startDiscoveringServices(pbledel!)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral). (\(error!.localizedDescription))")
        cleanup()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        var con = 0
        for pbledis in self.peripheralBLE {
           if (pbledis == peripheral){
                print("Device disconnected\(peripheral). (\(error!.localizedDescription))")
                self.peripheralBLE.remove(at: con)
            }
            con += 1
        }
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("Restaurar estado")
    }
    
/*****************************************************************************************************************************
******************************************************************************************************************************
******************************************************************************************************************************
*------------------------------------------------Parte de los servicios------------------------------------------------------*
******************************************************************************************************************************
******************************************************************************************************************************
*****************************************************************************************************************************/


    fileprivate func cleanup() {
        // Don't do anything if we're not connected
        // self.discoveredPeripheral.isConnected is deprecated
        
        for pble in self.peripheralBLE {
            if pble?.state != CBPeripheralState.connected { // explicit enum required to compile here?
                return
            }
            
            print("Vaos a ver si hay subscripciones a las caracteristicas")
            
            // See if we are subscribed to a characteristic on the peripheral
            if let services = pble?.services as [CBService]? {
                for service in services {
                    if let characteristics = service.characteristics as [CBCharacteristic]? {
                        for characteristic in characteristics {
                            if characteristic.uuid.isEqual(RXCharacteristicUUID) && characteristic.isNotifying {
                                pble?.setNotifyValue(false, for: characteristic)
                                // And we're done.
                                return
                            }
                        }
                    }
                }
            }
            // If we've got this far, we're connected, but we're not subscribed, so we just disconnect
            centralManager?.cancelPeripheralConnection(pble!)
        }
    }
    
    func startDiscoveringServices(_ perBLE: CBPeripheral) {
        perBLE.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
        if self.peripheralBLE.count != 0 {
            self.peripheralBLE.removeAll()
        }
        
        // Deallocating therefore send notification
        //self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        //let uuidsForBTService: [CBUUID] = [RXCharacteristicUUID]
        for  servicio in peripheral.services as [CBService]! {
            print("Descubriendo servicios --> \(servicio.uuid) del periferico \(peripheral.name!)")
            if (servicio.uuid == BLEServiceUUID){
                peripheral.discoverCharacteristics([RXCharacteristicUUID], for: servicio)
//                peripheral.discoverCharacteristics(uuidsForBTService, forService: servicio)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            cleanup()
            return
        }
        
        for characteristic in service.characteristics as [CBCharacteristic]! {
            if characteristic.uuid.isEqual(RXCharacteristicUUID) {
                print("Descubriendo caracteristicas --> \(characteristic.uuid) del periferico \(peripheral.name!)")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func convertirHexadecimalAUint(hexadecimal: String) -> UInt16{
        
        let chars = Array(hexadecimal.characters)
        let numbers = stride(from: 0, to: chars.count, by: 2).map() {
            strtoul(String(chars[$0 ..< min($0 + 2, chars.count)]), nil, 16)
        }
        //255*256 + 241
        return UInt16(numbers[0]*256 + numbers[1])
    }
    
    
    func convertirDatos(data: String) -> String! {
        let datosTroceados = data.components(separatedBy: " ")
        let cabecera: String = datosTroceados[0]
        
        var datoX : Double = 0.0
        var datoY : Double = 0.0
        var datoZ : Double = 0.0
        
        if cabecera == "a" {
            datoX = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[1]))) / 1000.0
            datoY = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[2]))) / 1000.0
            datoZ = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[3]))) / 1000.0

        }
        if cabecera == "g" {
            datoX = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[1]))) / 900.0
            datoY = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[2]))) / 900.0
            datoZ = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[3]))) / 900.0
        }
        if cabecera == "e" {
            datoX = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[1]))) / 900.0
            datoY = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[2]))) / 900.0
            datoZ = Double(Int16(bitPattern: convertirHexadecimalAUint(hexadecimal: datosTroceados[3]))) / 900.0
        }
        //print("Datos Convertidos: \(cabecera)  \(datoX) \(datoY) \(datoZ)")
        
        return  ("\(cabecera) \(datoX) \(datoY) \(datoZ) ")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        
        if (peripheral.name! == "RTX_IMU_1"){
            if let sfd = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                //nrf51_1.write(element: sfd as NSString)
                //print("\(Int64(Date().timeIntervalSince1970 * 1000)) \(sfd as String)")
                print("\(Double(clock()) / Double(CLOCKS_PER_SEC)) \(sfd as String)")
                aux = aux  + convertirDatos(data: (sfd as String))//(sfd as String)
                
                if tramas[0] == 3 {
                    tramas[0] = 0
                    
                    nrf51_1.removeAll()
                    nrf51_1 = aux
                    
                    nrf51[0].removeAll()
                    nrf51[0] = aux
                   // print("B1: \(nrf51[0]) ")
                    aux.removeAll()
                }
                tramas[0] = tramas[0] + 1
                //print("tramasRecebidas-->\(tramas)")
                //print("DATOS-->\(sfd)")
                //print("\(peripheral.name!)-->\(sfd)")
            }
        }
        
        if (peripheral.name! == "RTX_IMU_2"){
            if let sfd = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                aux2 = aux2  + convertirDatos(data: (sfd as String))//(sfd as String)
                if tramas[1] == 3 {
                    tramas[1] = 0
                    nrf51_2.removeAll()
                    nrf51_2 = aux2
                    
                    nrf51[1].removeAll()
                    nrf51[1] = aux
                    print("B2: \(nrf51[1]) ")
                    aux2.removeAll()
                }
                tramas[1] = tramas[1] + 1
                //print("\(peripheral.name!)-->\(sfd)")
            }
        }
        
        if (peripheral.name! == "RTX_IMU_3"){
            if let sfd = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                //nrf51_1.write(element: sfd as NSString)
                aux3 = aux3  + convertirDatos(data: (sfd as String))//(sfd as String)
                if tramas[2] == 3 {
                    tramas[2] = 0
                    nrf51_3.removeAll()
                    nrf51_3 = aux3
                    
                    nrf51[2].removeAll()
                    nrf51[2] = aux
                    print("B3: \(nrf51[2]) ")
                    aux3.removeAll()
                }
                tramas[2] = tramas[2] + 1
                //print("tramasRecebidas-->\(tramas)")
                //print("DATOS-->\(sfd)")
                //print("\(peripheral.name!)-->\(sfd)")
            }
        }
        
        if (peripheral.name! == "RTX_IMU_4"){
            if let sfd = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                //nrf51_1.write(element: sfd as NSString)
                aux4 = aux4  + convertirDatos(data: (sfd as String))//(sfd as String)
                if tramas[3] == 3 {
                    tramas[3]  = 0
                    nrf51_4.removeAll()
                    nrf51_4 = aux4
                    
                    nrf51[3].removeAll()
                    nrf51[3] = aux
                    print("B4: \(nrf51[3]) ")
                    aux4.removeAll()
                }
                tramas[3] = tramas[3] + 1
                //print("tramasRecebidas-->\(tramas)")
                //print("DATOS-->\(sfd)")
                //print("\(peripheral.name!)-->\(sfd)")
            }
        }
        
        if (peripheral.name! == "RTX_IMU_5"){
            if let sfd = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                //nrf51_1.write(element: sfd as NSString)
                aux5 = aux5  + convertirDatos(data: (sfd as String))//(sfd as String)
                if tramas[4]  == 3 {
                    tramas[4]  = 0
                    nrf51_5.removeAll()
                    nrf51_5 = aux5
                    
                    nrf51[4].removeAll()
                    nrf51[4] = aux
                    print("B5: \(nrf51[4]) ")
                    
                    aux5.removeAll()
                }
                tramas[4] = tramas[4] + 1
                //print("tramasRecebidas-->\(tramas)")
                //print("DATOS-->\(sfd)")
                //print("\(peripheral.name!)-->\(sfd)")
            }
        }
        
        if (peripheral.name! == "RTX_IMU_6"){
            if let sfd = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                //nrf51_1.write(element: sfd as NSString)
                aux6 = aux6  + convertirDatos(data: (sfd as String))//(sfd as String)
                if tramas[5]  == 3 {
                    tramas[5]  = 0
                    nrf51_6.removeAll()
                    nrf51_6 = aux6
                    
                    nrf51[5].removeAll()
                    nrf51[5] = aux
                    print("B6: \(nrf51[4]) ")
                    aux6.removeAll()
                }
                tramas[5] = tramas[5] + 1
                //print("tramasRecebidas-->\(tramas)")
                //print("DATOS-->\(sfd)")
                //print("\(peripheral.name!)-->\(sfd)")
            }
        }
        
        if (peripheral.name! == "RTX_IMU_7"){
            if let sfd = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue){
                //nrf51_1.write(element: sfd as NSString)
                aux7 = aux7  + convertirDatos(data: (sfd as String))//(sfd as String)
                if tramas[6] == 3 {
                    tramas[6] = 0
                    nrf51_7.removeAll()
                    nrf51_7 = aux7
                    
                    nrf51[6].removeAll()
                    nrf51[6] = aux
                    print("B7: \(nrf51[6]) ")
                    aux7.removeAll()
                }
                tramas[6] = tramas[6] + 1
                //print("tramasRecebidas-->\(tramas)")
                //print("DATOS-->\(sfd)")
                //print("\(peripheral.name!)-->\(sfd)")
            }
        }
        
        
        
        
        
        
    }
}
