//
//  MapaViewController.swift
//  Uber
//
//  Created by Bruno Lopes de Mello on 09/12/2017.
//  Copyright © 2017 Bruno Lopes de Mello. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class PassageiroViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var chamarButton: UIButton!
    var gerenciadorLocalizacao = CLLocationManager()
    var uberChamado = false //Alternador do botao
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.gerenciadorLocalizacao.delegate = self
        self.gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        self.gerenciadorLocalizacao.requestWhenInUseAuthorization()
        self.gerenciadorLocalizacao.startUpdatingLocation()
    }

    private func centralizar() {
        if let location = gerenciadorLocalizacao.location?.coordinate {
            let regiao = MKCoordinateRegionMakeWithDistance(location, 200, 200)
            self.mapa.setRegion(regiao, animated: true)
            
            //remove as anotacoes antes de criar
            mapa.removeAnnotations(mapa.annotations)
            
            //Cria uma anotacao para o local do usuario
            let anotacaoUsuario = MKPointAnnotation()
            anotacaoUsuario.coordinate = location
            anotacaoUsuario.title = "Seu Local"
            mapa.addAnnotation(anotacaoUsuario)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.centralizar()
        self.gerenciadorLocalizacao.stopUpdatingLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    @IBAction func deslogar(_ sender: Any) {
        
        let autenticacao = Auth.auth()
        
        self.dismiss(animated: true) {
            
            do {
                try autenticacao.signOut()
            } catch let erro {
                print("Erro: \(erro.localizedDescription)")
            }
        }
    }
    
    
    @IBAction func chamarUber(_ sender: Any) {
        
        let database = Database.database().reference()
        let autenticacao = Auth.auth()
        let requisicao = database.child("requisicoes")
        
        if let emailUsuario = autenticacao.currentUser?.email {
            let latitude = self.gerenciadorLocalizacao.location?.coordinate.latitude
            let longitude = self.gerenciadorLocalizacao.location?.coordinate.longitude
            
            if self.uberChamado {//Uber chamado
                
               self.alternaBotaoChamarUber()
                
                //remover requisicao
                let requisicao = database.child("requisicoes")
                
                //ordernar por email para um email especifico
                requisicao.queryOrdered(byChild: "email").queryEqual(toValue: emailUsuario).observeSingleEvent(of: DataEventType.childAdded, with: { (snapshot) in
                    
                    //ref é o ID gerado eplo childByAutoId
                    snapshot.ref.removeValue()
                })
                
            } else {//uber nao foi chamado
                
                self.alternaBotaoCancelarUber()
                
                let dadosUsuario = [
                    "email" : emailUsuario,
                    "nome" : "Bruno Lopes",
                    "latitude" : latitude!,
                    "longitude" : longitude!
                    ] as [String : Any]
                
                requisicao.childByAutoId().setValue(dadosUsuario)
                
            }
        }
        
    }
    
    func alternaBotaoCancelarUber() {
        self.chamarButton.setTitle("Cancelar Uber", for: .normal)
        self.chamarButton.backgroundColor = UIColor.red
        self.uberChamado = true
    }
    
    func alternaBotaoChamarUber() {
        self.chamarButton.setTitle("Chamar Uber", for: .normal)
        self.chamarButton.backgroundColor = UIColor(red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.uberChamado = false
    }

}
