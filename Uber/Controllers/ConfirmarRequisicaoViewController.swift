//
//  ConfirmarRequisicaoViewController.swift
//  Uber
//
//  Created by Bruno Lopes de Mello on 30/12/2017.
//  Copyright © 2017 Bruno Lopes de Mello. All rights reserved.
//

import UIKit
import MapKit
import Firebase

enum StatusCorrida: String {
    
    case EmRequisicao, PegarPassageiro, IniciarViagem, EmViagem
}

class ConfirmarRequisicaoViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaoAceitarCorrida: UIButton!
    
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var status: StatusCorrida = .EmRequisicao
    var gerenciadorLocalizacao = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //configuracao do gerenciador de localizacao
        self.gerenciadorLocalizacao.delegate = self
        self.gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        self.gerenciadorLocalizacao.requestWhenInUseAuthorization()
        self.gerenciadorLocalizacao.startUpdatingLocation()
        
        //configurar a area inicial do mapa
        let regiao = MKCoordinateRegionMakeWithDistance(self.localPassageiro, 200, 200)
        self.mapa.setRegion(regiao, animated: true)
        
        //adiciona a anotacao para o passageiro
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localPassageiro
        anotacaoPassageiro.title = self.nomePassageiro
        mapa.addAnnotation(anotacaoPassageiro)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordenadas = manager.location?.coordinate {
            self.localMotorista = coordenadas
            self.atualizarLocalMotorista()
        }
    }
    
    func atualizarLocalMotorista() {
        
        // Atualizar o local do motorista no Firebase
        let database = Database.database().reference()
        
        if self.emailPassageiro != "" {
            
            let requisicoes = database.child("requisicoes")
            let consultaRequsicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
            
            consultaRequsicao.observeSingleEvent(of: .childAdded, with: { (snapshot) in
                
                if let dados = snapshot.value as? NSDictionary {
                    
                    if let statusR = dados["status"] as? String {
                        
                        switch statusR {
                            
                        //status PegarPassageiro
                        case StatusCorrida.PegarPassageiro.rawValue:
                            let dadosMotorista = [
                                "motoristaLatitude" : self.localMotorista.latitude,
                                "motoristaLongitude": self.localMotorista.longitude
                            ]
                            //salvar os dados no Firebase
                            snapshot.ref.updateChildValues(dadosMotorista)
                            self.pegarPassageiro()
                            break
                        default: break
                            //do nothing for while
                        }
                    }
                }
            })
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pegarPassageiro() {
        // alterar o status
        self.status = StatusCorrida.PegarPassageiro
        
        //Alternar botao
        self.alternaBotaoPegarPassageiro()
    }
    
    func alternaBotaoPegarPassageiro() {
        self.botaoAceitarCorrida.setTitle("A caminho do passageiro", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = false
    }
    
    @IBAction func aceitarCorrida(_ sender: Any) {
        
        if self.status == StatusCorrida.EmRequisicao {
            
            //atualizar requisicao
            let database = Database.database().reference()
            let autenticacao = Auth.auth()
            let requisicoes = database.child("requisicoes")
            
            if let emailMotorista = autenticacao.currentUser?.email {
                requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro).observeSingleEvent(of: .childAdded) { (snapshot) in
                    
                    let dadosMotorista = [
                        "motoristaEmail" : emailMotorista,
                        "motoristaLatitude" : self.localMotorista.latitude,
                        "motoristaLongitude": self.localMotorista.longitude,
                        "status" : StatusCorrida.PegarPassageiro.rawValue
                        ] as [String : Any]
                    
                    snapshot.ref.updateChildValues(dadosMotorista)
                    
                    self.pegarPassageiro()
                }
            }
            
            //criar rota até do motorista ao passageiro
            let passageiroCLL = CLLocation(latitude: self.localPassageiro.latitude, longitude: self.localPassageiro.longitude)
            CLGeocoder().reverseGeocodeLocation(passageiroCLL) { (local, erro) in
                
                if erro == nil {
                    if let dadosLocal = local?.first {
                        let placeMark = MKPlacemark(placemark: dadosLocal)
                        
                        //exibir o caminho para o passageiro
                        let mapaItem = MKMapItem(placemark: placeMark)
                        mapaItem.name = self.nomePassageiro
                        
                        let opcoes = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        mapaItem.openInMaps(launchOptions: opcoes)
                    }
                }
            }
        } else {
            
        } //fim verificacao de status
        
    }
}
