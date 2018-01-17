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
        self.gerenciadorLocalizacao.allowsBackgroundLocationUpdates = true
        
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
                            
                            /*
                             Verifica se o motorista está próximo
                             para iniciar a corrida
                             */
                            
                            //Calcula a distancia entre o motorista e o passageiro
                            let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
                            let passageiroLocation = CLLocation(latitude: self.localPassageiro.latitude, longitude: self.localPassageiro.longitude)
                            
                            let distancia = motoristaLocation.distance(from: passageiroLocation)
                            let distanciaKm = distancia / 1000
                            let distanciaFinal = distanciaKm.rounded(toPlaces: 2)
                            
                            var novoStatus = self.status.rawValue
                            if distanciaFinal <= 0.5 {
                                novoStatus = StatusCorrida.IniciarViagem.rawValue
                            }
                            
                            let dadosMotorista = [
                                "motoristaLatitude" : self.localMotorista.latitude,
                                "motoristaLongitude": self.localMotorista.longitude,
                                "status": novoStatus
                                ] as [String : Any]
                            
                            //salvar os dados no Firebase
                            snapshot.ref.updateChildValues(dadosMotorista)
                            self.pegarPassageiro()
                            break
                            
                        case StatusCorrida.IniciarViagem.rawValue:
                            
                            self.alternaBotaoIniciarViagem()
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
    
    func alternaBotaoIniciarViagem() {
        self.botaoAceitarCorrida.setTitle("Iniciar viagem", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = true
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
