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
    
    case EmRequisicao, PegarPassageiro, IniciarViagem, EmViagem, ViagemFinalizada
}

class ConfirmarRequisicaoViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var botaoAceitarCorrida: UIButton!
    
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    var localDestino = CLLocationCoordinate2D()
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
        
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        let consultaRequsicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
        consultaRequsicao.observe(.childChanged) { (snapshot) in
            
            if let dados  = snapshot.value as? [String:Any] {
                if let statusR = dados["status"] as? String {
                    
                    self.recarregarTelaStatus(status: statusR, dados: dados)
                }
            }
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        let consultaRequsicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
        consultaRequsicao.observeSingleEvent(of: .childAdded) { (snapshot) in
            
            if let dados  = snapshot.value as? [String:Any] {
                if let statusR = dados["status"] as? String {
                    
                    self.recarregarTelaStatus(status: statusR, dados: dados)
                }
            }
            
        }
    }
    
    func recarregarTelaStatus(status: String, dados: [String: Any]) {
        
        //Carregar a tela baseada nos status
        
        switch status {
        case StatusCorrida.PegarPassageiro.rawValue:
            print("status: PegarPassageiro")
            
            self.pegarPassageiro()
            
            self.exibeMotoristaPassageiro(lPartida: self.localMotorista, lDestino: self.localPassageiro, tPartida: "Meu Local", tDestino: "Passageiro")
            break
        case StatusCorrida.EmRequisicao.rawValue:
            break
        case StatusCorrida.IniciarViagem.rawValue:
            print("status: IniciarViagem")
            
            self.alternaBotaoIniciarViagem()
            self.status = .IniciarViagem
            
            //Recuperar local do destino
            if let latDestino = dados["destinoLatitude"] as? Double {
                if let lonDestino = dados["destinoLongitude"] as? Double {
                    self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                }
            }
           
            //Exibir motorista passageiro
            self.exibeMotoristaPassageiro(lPartida: self.localMotorista, lDestino: self.localPassageiro, tPartida: "Motorista", tDestino: "Passageiro ")
            
            break
        case StatusCorrida.EmViagem.rawValue:
            self.status = .EmViagem
            self.alterBotaoPendenteFinalizarViagem()
            
            //atualizar o local do motorista e do passageiro
            if let latDestino = dados["destinoLatitude"] as? Double {
                if let lonDestino = dados["destinoLongitude"] as? Double {
                    self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                    self.exibeMotoristaPassageiro(lPartida: self.localPassageiro, lDestino: self.localDestino, tPartida: "Motorista", tDestino: "Destino ")
                }
            }
            break
        default:
            break
        }
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
                            
                            if distanciaFinal <= 0.5 {
                                self.atualizaStatusRequisicao(status: StatusCorrida.IniciarViagem.rawValue)
                            }
                        
                            
                            break
                            
                        case StatusCorrida.IniciarViagem.rawValue:
                            
                            //Calcula a distancia entre o motorista e o passageiro
                            let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
                            let passageiroLocation = CLLocation(latitude: self.localPassageiro.latitude, longitude: self.localPassageiro.longitude)
                            
                            let distancia = motoristaLocation.distance(from: passageiroLocation)
                            let distanciaKm = distancia / 1000
                            let distanciaFinal = distanciaKm.rounded(toPlaces: 2)
                            
                            if distanciaFinal > 0.5 {
                                self.atualizaStatusRequisicao(status: StatusCorrida.PegarPassageiro.rawValue)
                            }
                            
                            //Exibir motorista passageiro
                            self.exibeMotoristaPassageiro(lPartida: self.localMotorista, lDestino: self.localPassageiro, tPartida: "Motorista", tDestino: "Passageiro ")
                            
//                            self.alternaBotaoIniciarViagem()
                            
                            /*if let latDestino = dados["destinoLatitude"] as? Double {
                                if let lonDestino = dados["destinoLongitude"] as? Double {
                                    
                                    self.localDestino = CLLocationCoordinate2D(latitude: latDestino, longitude: lonDestino)
                                    
                                    
                                    
                                }
                            }*/
                            
                            
                            break
                            
                        default: break
                            //do nothing for while
                        }
                        
                        let dadosMotorista = [
                            "motoristaLatitude" : self.localMotorista.latitude,
                            "motoristaLongitude": self.localMotorista.longitude
                            ] as [String : Any]
                        
                        //salvar os dados no Firebase
                        snapshot.ref.updateChildValues(dadosMotorista)
                    }
                }
            })
            
        }
        
    }
    
    func atualizaStatusRequisicao(status: String) {
        if status != "" && self.emailPassageiro != "" {
            
            let database = Database.database().reference()
            let requisicoes = database.child("requisicoes")
            let consultaRequsicao = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
            
            consultaRequsicao.observeSingleEvent(of: .childAdded, with: { (snapshot) in
                
                if (snapshot.value as? [String:Any]) != nil {
                    let dadosAtualizar = [
                        "status" : status
                    ]
                    snapshot.ref.updateChildValues(dadosAtualizar)
//                    self.alternaBotaoIniciarViagem()
                }
            })
        }
    }
    
    func exibeMotoristaPassageiro(lPartida: CLLocationCoordinate2D, lDestino: CLLocationCoordinate2D, tPartida: String, tDestino: String) {
        
        //Remover primeiro todas as anotacoes
        self.mapa.removeAnnotations(mapa.annotations)
        
        let latDiferenca = abs(lPartida.latitude - lDestino.latitude) * 300000
        let lonDiferenca = abs(lPartida.longitude - lDestino.longitude) * 300000
        
        let regiao = MKCoordinateRegionMakeWithDistance(lPartida, latDiferenca, lonDiferenca)
        self.mapa.setRegion(regiao, animated: true)
        
        //Anotacao partida
        let anotacaoPartida = MKPointAnnotation()
        anotacaoPartida.coordinate = lPartida
        anotacaoPartida.title = "Partida"
        mapa.addAnnotation(anotacaoPartida)
        
        //Anotacao destino
        let anotacaoDestino = MKPointAnnotation()
        anotacaoDestino.coordinate = lDestino
        anotacaoDestino.title = "Destino"
        mapa.addAnnotation(anotacaoDestino)
        
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
        print("Alternou o botao para iniciar viagem")
        self.botaoAceitarCorrida.setTitle("Iniciar viagem", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = true
    }
    
    func alternaBotaoViagemFinalizada(preco: Double) {
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = false
        
        //Formata numero
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.locale = Locale(identifier: "pt_BR")
        
        let precoFinal = nf.string(from: NSNumber(value: preco))
        
        self.botaoAceitarCorrida.setTitle("Viagem finalizada - R$ " + precoFinal!, for: .normal)
    }
    
    func alternaBotaoPegarPassageiro() {
        self.botaoAceitarCorrida.setTitle("A caminho do passageiro", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = false
    }
    
    func alterBotaoPendenteFinalizarViagem() {
        print("Alternou o botao para em viagem")
        self.botaoAceitarCorrida.setTitle("Finalizar viagem", for: .normal)
        self.botaoAceitarCorrida.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.botaoAceitarCorrida.isEnabled = true
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
                    self.exibeMotoristaPassageiro(lPartida: self.localMotorista, lDestino: self.localPassageiro, tPartida: "Meu Local", tDestino: "Passageiro")

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
        } else if (self.status == StatusCorrida.IniciarViagem){
            self.iniciarViagemDestino()
        } else if (self.status == StatusCorrida.EmViagem) {
            self.finalizarViagem()
        } //fim verificacao de status
        
    }
    
    func finalizarViagem() {
        
        //Altera Status
        self.status = .ViagemFinalizada
        
        //Calcular o preço da viagem
        let precoKM: Double = 4
        
        //Recuperar os dados para atualizar o preco
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro)
        
        consultaRequisicoes.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let dados = snapshot.value as? [String: Any] {
                if let latInicial = dados["latitude"] as? Double {
                    if let lonInicial = dados["longitude"] as? Double {
                        if let latDestino = dados["destinoLatitude"] as? Double {
                            if let lonDestino = dados["destinoLongitude"] as? Double {
                                
                                let inicio = CLLocation(latitude: latInicial, longitude: lonInicial)
                                
                                let fim = CLLocation(latitude: latDestino, longitude: lonDestino)
                                
                                //Calcular distancia
                                let distancia = inicio.distance(from: fim) / 1000
                                let distanciaFormatada = distancia.rounded(toPlaces: 2)
                                let precoViagem = distanciaFormatada * precoKM
                                
                                let dadosAtualizar = [
                                    "precoViagem" : precoViagem,
                                    "distanciaPercorrida" : distanciaFormatada
                                ]
                                
                                snapshot.ref.updateChildValues(dadosAtualizar)
                                
                                //atualizar requisicao no firebase
                                self.atualizaStatusRequisicao(status: self.status.rawValue)
                                
                                //Alternar para viagem finalizada
                                self.alternaBotaoViagemFinalizada(preco: precoViagem)
                                
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func iniciarViagemDestino() {
        
        //Altera o status
        self.status = .EmViagem
        
        //Atualizar a requisição no Firebase
        self.atualizaStatusRequisicao(status: self.status.rawValue)
        
        //Exibir o caminho para o destino do mapa
        let destinoCLL = CLLocation(latitude: self.localDestino.latitude, longitude: self.localDestino.longitude)
        
        CLGeocoder().reverseGeocodeLocation(destinoCLL) { (local, erro) in
            
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
        
    }
}
