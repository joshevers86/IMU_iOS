//
//  ViewController.swift
//  accelerometro
//
//  Created by Jose Navarro Alabarta on 28/4/17.
//  Copyright © 2016 ai2-upv. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
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
    
    
    fileprivate let manejador = CMMotionManager()
    fileprivate let cola = OperationQueue()
    fileprivate let colaGyro = OperationQueue()
    var runLecturaBle : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        inicio = BLEDiscovery()
        datosBluetooth()
    }
    

    @IBAction func iniciarLectura(_ sender: Any) {
        lecturaAcelerometro()
        lecturaGiroscopo()
        runLecturaBle = true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func pararLectura(_ sender: Any) {
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
                        
                            self.xLectABLE.text = "\(datosTroceados[5])"
                            self.yLectABLE.text = "\(datosTroceados[6])"
                            self.zLectABLE.text = "\(datosTroceados[7])"
                            
                            self.xLectGBLE.text = "\(datosTroceados[1])"
                            self.yLectGBLE.text = "\(datosTroceados[2])"
                            self.zLectGBLE.text = "\(datosTroceados[3])"
                            
                            print("Datos: \(datosTroceados[0]) \(datosTroceados[1]) \(datosTroceados[2]) \(datosTroceados[3]) \(datosTroceados[4]) \(datosTroceados[5]) \(datosTroceados[6]) \(datosTroceados[7]) ")
                        })
                    }
                }
                usleep(20_000) //20ms
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
}
