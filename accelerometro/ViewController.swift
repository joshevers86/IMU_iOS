//
//  ViewController.swift
//  accelerometro
//
//  Created by Jose Navarro Alabarta on 28/4/17.
//  Copyright © 2016 ai2-upv. All rights reserved.
//

import UIKit
import CoreMotion
import MessageUI


class ViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    var inicio : BLEDiscovery!
    
    @IBOutlet weak var xLec: UILabel!
    @IBOutlet weak var yLec: UILabel!
    @IBOutlet weak var zLec: UILabel!
    
    @IBOutlet weak var xLectG: UILabel!
    @IBOutlet weak var yLectG: UILabel!
    @IBOutlet weak var zLectZ: UILabel!
    
    @IBOutlet weak var xLectABLE: UILabel!
    @IBOutlet weak var yLectABLE: UILabel!
    @IBOutlet weak var zLectABLE: UILabel!
    
    @IBOutlet weak var xLectGBLE: UILabel!
    @IBOutlet weak var yLectGBLE: UILabel!
    @IBOutlet weak var zLectGBLE: UILabel!
    
    @IBOutlet weak var heading: UILabel!
    @IBOutlet weak var roll: UILabel!
    @IBOutlet weak var pitch: UILabel!
    
    @IBOutlet weak var scroll: UIScrollView!
    
    fileprivate let manejador = CMMotionManager()
    fileprivate let cola = OperationQueue()
    fileprivate let colaGyro = OperationQueue()
    var runLecturaBle : Bool = false
    
    var directorio : String = String()
    var manejadorFicheros : FileManager? = nil
    let nombreFichero : String = "testimu.txt"
    var path : URL? = nil
    
    var salvarDatos : String = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        inicio = BLEDiscovery()
        datosBluetooth()
        
        
        directorio = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
        manejadorFicheros = FileManager.default
        if let dir = manejadorFicheros!.urls(for: .documentDirectory, in: .userDomainMask).first {
            
            self.path = dir.appendingPathComponent(nombreFichero)
            
        }
        self.salvarDatos = "timeStamp \t xAcciOS(G) \t yAcciOS(G) \t zAcciOS(G) \t xGyriOS(rps) \t yGyriOS(rps) \t zGyriOS(rps) \t xAccBLE(G) \t yAccBLE(G) \t zAccBLE(G) \t xGyrBLE(rps) \t yGyrBLE(rps) \t zGyrBLE(rps) \t xEulerBLE(rad) \t yEulerBLE(rad) \t zEulerBLE(rad) \n"
        
    }
    

    @IBAction func iniciarLectura(_ sender: Any) {
        lecturaAcelerometro()
        lecturaGiroscopo()
        inicio.connectDevice()
        runLecturaBle = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pararLectura(_ sender: Any) {
        inicio.disconnectDevice()
        self.manejador.stopAccelerometerUpdates()
        self.manejador.stopGyroUpdates()
        runLecturaBle = false
    }
    
    func datosBluetooth(){
        let backgroundQueue = DispatchQueue(label: "es.upv.ai2", qos: .background, target: nil)
        backgroundQueue.async {
            while(true){
                if self.runLecturaBle {
                   
                    let datosBLE = self.inicio.nrf51[0]
                    if !datosBLE.isEmpty {
                        DispatchQueue.main.async(execute: {
                            let datosTroceados = datosBLE.components(separatedBy: " ")
                        
                            self.xLectABLE.text = "\(datosTroceados[9])"
                            self.yLectABLE.text = "\(datosTroceados[10])"
                            self.zLectABLE.text = "\(datosTroceados[11])"
                            
                            self.xLectGBLE.text = "\(datosTroceados[1])"
                            self.yLectGBLE.text = "\(datosTroceados[2])"
                            self.zLectGBLE.text = "\(datosTroceados[3])"
                            
                            self.heading.text = "\(datosTroceados[5])"
                            self.roll.text = "\(datosTroceados[6])"
                            self.pitch.text = "\(datosTroceados[7])"
                            
                            //print("Datos: \(datosTroceados[0]) \(datosTroceados[1]) \(datosTroceados[2]) \(datosTroceados[3]) \(datosTroceados[4]) \(datosTroceados[5]) \(datosTroceados[6]) \(datosTroceados[7]) ")
                            
                            //print( self.xLec.text! + "\t" + self.yLec.text! + "\t" + self.zLec.text! + "\t" + self.xLectG.text! + "\t" + self.yLectG.text! + "\t" + self.zLectZ.text! + "\t" + self.xLectABLE.text! + "\t" + self.yLectABLE.text! + "\t" + self.yLectABLE.text! + "\t" + self.xLectGBLE.text! + "\t" + self.yLectGBLE.text! + "\t" + self.zLectGBLE.text! )
                            
                            
                            self.salvarDatos += "\(Double(clock()) / Double(CLOCKS_PER_SEC))" + "\t" + self.xLec.text! + "\t" + self.yLec.text! + "\t" + self.zLec.text! + "\t" + self.xLectG.text! + "\t" + self.yLectG.text! + "\t" + self.zLectZ.text! + "\t" + self.xLectABLE.text! + "\t" + self.yLectABLE.text! + "\t" + self.zLectABLE.text! + "\t" + self.xLectGBLE.text! + "\t" + self.yLectGBLE.text! + "\t" + self.zLectGBLE.text! + "\t" + self.heading.text! + "\t" + self.roll.text! + "\t" + self.pitch.text! + "\n"
                            
                            
                        })
                    }
                }
                usleep(1_000) //20ms 1ms sin que se repitan los datos
            }
        }
    }
    
    func lecturaGiroscopo(){
        
        if manejador.isGyroAvailable{
            manejador.gyroUpdateInterval = 1.0/500.0
            manejador.startGyroUpdates(to: colaGyro,withHandler: {
                datos, error in
                if error != nil {
                    self.manejador.stopGyroUpdates()
                }else {
                    DispatchQueue.main.async(execute: {
                        self.xLectG.text = "\(datos!.rotationRate.x)"
                        self.yLectG.text = "\(datos!.rotationRate.y)"
                        self.zLectZ.text = "\(datos!.rotationRate.z)"
                    })
                }
            })
        }
    }
    
    func lecturaMagnetometro(){
        if manejador.isMagnetometerAvailable{
        }
    }
    
    
    func lecturaAcelerometro(){
        if manejador.isAccelerometerAvailable {
            manejador.accelerometerUpdateInterval = 1.0/500.0 //lectura 10 veces por segundo
            manejador.startAccelerometerUpdates(to: cola, withHandler:  {
                datos, error in
                if error != nil {
                    self.manejador.stopAccelerometerUpdates()
                } else {
                    DispatchQueue.main.async(execute: {
                        self.xLec.text = "\(datos!.acceleration.x)"
                        self.yLec.text = "\(datos!.acceleration.y)"
                        self.zLec.text = "\(datos!.acceleration.z)"
                        /*if (datos!.acceleration.z > 1.1 || datos!.acceleration.z > 1.1 || datos!.acceleration.z > 1.1 ){
                            self.sacudida.text = "sacudida"
                        }*/
                    })
                }
            })
        }else {
            print ("acc no available")
        }
    }
    
    
    
    /*eMAIL*/
    
    
    @IBAction func enviarCorreo(_ sender: AnyObject) {
        
        print(self.salvarDatos)
        if !escribirDatosEnFichero(data: self.salvarDatos){
            print("No se ha podido escribir el fichero.")
        }
        
        
        //Check to see the device can send email.
        if( MFMailComposeViewController.canSendMail() ) {
            
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            
            //Set the subject and message of the email
            
            mailComposer.setToRecipients(["jonaal1@upv.es"])
            mailComposer.setSubject("Fichero datos IMU-BLE y matriz")
            mailComposer.setMessageBody("Fichero para cargarlo en Matlab.", isHTML: false)
            
            
            if let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
                
                let fPath = filePath.appendingPathComponent(nombreFichero)
                if let fileData = NSData(contentsOfFile: fPath.path ) {
                    
                    mailComposer.addAttachmentData(fileData as Data, mimeType: "text/plain", fileName: "testimu")
                }
            }
            
            present(mailComposer, animated: true)
            
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    
    
     func escribirDatosEnFichero(data: String!) -> Bool{
        do {
            try data.write(to: self.path!, atomically: true, encoding: String.Encoding.utf8)
            return true
        }
        catch {
            print("NO se puede guardar: \(data)")
            return false
        }
    }
    
     func clearTempFolder() {
        //let fileManager = FileManager.default
        let tempFolderPath = NSTemporaryDirectory()
        
        do{
            let pat = try manejadorFicheros?.contentsOfDirectory(atPath: directorio)
            for filePath in pat! {
                print(filePath)
                try manejadorFicheros?.removeItem(atPath: directorio+"/" + filePath)
            }
        } catch let err as NSError{
            print("Could not clear temp folder: \(err.debugDescription)")
        }
        
        
        do {
            let filePaths = try manejadorFicheros?.contentsOfDirectory(atPath: tempFolderPath)
            for filePath in filePaths! {
                try manejadorFicheros?.removeItem(atPath: NSTemporaryDirectory() + filePath)
            }
        } catch let error as NSError {
            print("Could not clear temp folder: \(error.debugDescription)")
        }
    }

    
    
    
    
}
