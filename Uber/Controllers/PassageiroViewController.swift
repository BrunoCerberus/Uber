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

class PassageiroViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    
    
    @IBOutlet weak var areaEndereco: UIView!
    @IBOutlet weak var marcadorLocalPassageiro: UIView!
    @IBOutlet weak var marcadorLocalDestino: UIView!
    @IBOutlet weak var enderecoDestinoCampo: UITextField!
    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var chamarButton: UIButton!
    var gerenciadorLocalizacao = CLLocationManager()
    var uberChamado = false //Alternador do botao
    var uberACaminho = false
    var localUsuario = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.gerenciadorLocalizacao.delegate = self
        self.gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        self.gerenciadorLocalizacao.requestWhenInUseAuthorization()
        self.gerenciadorLocalizacao.startUpdatingLocation()
        
        //Configurar o arrendondamento dos marcadores
        self.marcadorLocalPassageiro.layer.cornerRadius = 7.5
        self.marcadorLocalPassageiro.clipsToBounds = true
        self.marcadorLocalDestino.layer.cornerRadius = 7.5
        self.marcadorLocalDestino.clipsToBounds = true
        self.areaEndereco.layer.cornerRadius = 10
        self.areaEndereco.clipsToBounds = true
        
        // Verifica se o usuario ja possui uma requisicao
        let database = Database.database().reference()
        let autenticacao = Auth.auth()
        
        if let emailUsuario = autenticacao.currentUser?.email {
            let requisicoes = database.child("requisicoes")
            let consultaRequisicoes = requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: emailUsuario)
            
            //Adiciona ouvinte para quando o usuario chamar Uber
            consultaRequisicoes.observeSingleEvent(of: .childAdded, with: { (snapshot) in
                if snapshot.value != nil {
                    self.alternaBotaoCancelarUber()
                }
            })
            
            //Adiciona ouvinte para quando motorista aceitar corrida
            consultaRequisicoes.observe(.childChanged, with: { (snapshot) in
                
                if let dados = snapshot.value as? NSDictionary {
                    
                    if let status = dados["status"] as? String {
                        
                        switch status {
                        case StatusCorrida.PegarPassageiro.rawValue:
                            if let latMotorista = dados["motoristaLatitude"] {
                                if let lonMotorista = dados["motoristaLongitude"] {
                                    self.localMotorista = CLLocationCoordinate2D(latitude: latMotorista as! CLLocationDegrees, longitude: lonMotorista as! CLLocationDegrees)
                                    self.exibirMotoristaPassageiro()
                                }
                            }
                            break
                            
                        case StatusCorrida.EmViagem.rawValue:
                            self.alternaBotaoEmViagem()
                            break
                            
                        case StatusCorrida.ViagemFinalizada.rawValue:
                            
                            if let preco = dados["precoViagem"] as? Double {
                                self.alternaBotaoViagemFinalizada(preco: preco)
                            }
                            break
                            
                        default:
                            break
                        }
                    }
                }
            })
        }
    }
    
    func alternaBotaoViagemFinalizada(preco: Double) {
        self.chamarButton.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.chamarButton.isEnabled = false
        
        //Formata numero
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.locale = Locale(identifier: "pt_BR")
        
        let precoFinal = nf.string(from: NSNumber(value: preco))
        
        self.chamarButton.setTitle("Viagem finalizada - R$ " + precoFinal!, for: .normal)
    }
    
    func alternaBotaoEmViagem() {
        self.chamarButton.setTitle("Em viagem", for: .normal)
        self.chamarButton.backgroundColor = UIColor(displayP3Red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        self.chamarButton.isEnabled = false
    }
    
    func exibirMotoristaPassageiro() {
        
        self.uberACaminho = true
        
        //Calcular distancia entre motorista e passageiro
        let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
        let passageiroLocation = CLLocation(latitude: self.localUsuario.latitude, longitude: self.localUsuario.longitude)
        
        let distancia = motoristaLocation.distance(from: passageiroLocation)
        let distanciaKm = distancia / 1000
        let distanciaFinal = distanciaKm.rounded(toPlaces: 2)
        
        let strDistancia = distanciaFinal >= 1.0 ? "\(distanciaFinal) KM distante" :  "\(distanciaFinal * 1000) Metros distante"
        
        self.chamarButton.backgroundColor = UIColor(displayP3Red: 0.067, green: 0.576, blue: 0.604, alpha: 1)
        self.chamarButton.setTitle("Motorista " + strDistancia, for: UIControlState.normal)
        
        //Exibir passageiro e motorista no mapa
        
        //Remover primeiro todas as anotacoes
        self.mapa.removeAnnotations(mapa.annotations)
        
        let latDiferenca = abs(self.localUsuario.latitude - self.localMotorista.latitude) * 300000
        let lonDiferenca = abs(self.localUsuario.longitude - self.localMotorista.longitude) * 300000
        
        let regiao = MKCoordinateRegionMakeWithDistance(self.localUsuario, latDiferenca, lonDiferenca)
        self.mapa.setRegion(regiao, animated: true)
        
        //Anotacao motorista
        let anotacaoMotorista = MKPointAnnotation()
        anotacaoMotorista.coordinate = self.localMotorista
        anotacaoMotorista.title = "Motorista"
        mapa.addAnnotation(anotacaoMotorista)
        
        //Anotacao passageiro
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localUsuario
        anotacaoPassageiro.title = "Passageiro"
        mapa.addAnnotation(anotacaoPassageiro)
        
    }
    
    private func centralizar() {
        if let location = gerenciadorLocalizacao.location?.coordinate {
            self.localUsuario = (gerenciadorLocalizacao.location?.coordinate)!
            
            if self.uberACaminho {
                
                self.exibirMotoristaPassageiro()
                
            } else {
                
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
        
        if let emailUsuario = autenticacao.currentUser?.email {
            
            if self.uberChamado {//Uber chamado
                
                self.alternaBotaoChamarUber()
                
                //remover requisicao
                let requisicao = database.child("requisicoes")
                
                //ordernar por email para um email especifico
                requisicao.queryOrdered(byChild: "email").queryEqual(toValue: emailUsuario).observeSingleEvent(of: DataEventType.childAdded, with: { (snapshot) in
                    
                    //ref é o ID gerado pelo childByAutoId
                    snapshot.ref.removeValue()
                })
                
            } else {//uber nao foi chamado
                
                self.salvarRequisicao()
                
            } //fim else
            
            
        }
        
    }
    
    func salvarRequisicao() {
        
        let database = Database.database().reference()
        let autenticacao = Auth.auth()
        let requisicao = database.child("requisicoes")
        
        if let idUsuario = autenticacao.currentUser?.uid {
            if let emailUsuario = autenticacao.currentUser?.email {
                if let enderecoDestino = self.enderecoDestinoCampo.text {
                    if enderecoDestino != "" {
                        
                        //Recuperar informacoes do local baseado pelo nome do endereco
                        CLGeocoder().geocodeAddressString(enderecoDestino, completionHandler: { (local, erro) in
                            
                            if erro == nil {
                                
                                if let dadosLocal = local?.first {
                                    
                                    var rua = ""
                                    if dadosLocal.thoroughfare != nil {
                                        rua = dadosLocal.thoroughfare!
                                    }
                                    
                                    var numero = ""
                                    if dadosLocal.subThoroughfare != nil {
                                        numero = dadosLocal.subThoroughfare!
                                    }
                                    
                                    var bairro = ""
                                    if dadosLocal.subLocality != nil {
                                        bairro = dadosLocal.subLocality!
                                    }
                                    
                                    var cidade = ""
                                    if dadosLocal.locality != nil {
                                        cidade = dadosLocal.locality!
                                    }
                                    
                                    var cep = ""
                                    if dadosLocal.postalCode != nil {
                                        cep = dadosLocal.postalCode!
                                    }
                                    
                                    let enderecoCompleto = "\(rua), \(numero), \(bairro) - \(cidade) - \(cep)"
                                    
                                    if let latDestino = dadosLocal.location?.coordinate.latitude {
                                        if let lonDestino = dadosLocal.location?.coordinate.longitude {
                                            
                                            let alert = UIAlertController(title: "Confirme seu endereço!", message: enderecoCompleto, preferredStyle: .alert)
                                            let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                                            let confirmAction = UIAlertAction(title: "Confirmar", style: .default, handler: { (action) in
                                                
                                                let latitude = self.gerenciadorLocalizacao.location?.coordinate.latitude
                                                let longitude = self.gerenciadorLocalizacao.location?.coordinate.longitude
                                                
                                                //recuperar o nome do usuario
                                                let database = Database.database().reference()
                                                let usuarios = database.child("usuarios").child(idUsuario)
                                                
                                                usuarios.observeSingleEvent(of: .value, with: { (snapshot) in
                                                    let dados = snapshot.value as? NSDictionary
                                                    let nomeUsuario = dados!["nome"] as! String
                                                    
                                                    self.alternaBotaoCancelarUber()
                                                    
                                                    let dadosUsuario = [
                                                        "destinoLatitude" : latDestino,
                                                        "destinoLongitude" : lonDestino,
                                                        "email" : emailUsuario,
                                                        "nome" : nomeUsuario,
                                                        "latitude" : latitude!,
                                                        "longitude" : longitude!
                                                        ] as [String : Any]
                                                    
                                                    requisicao.childByAutoId().setValue(dadosUsuario)
                                                    
                                                    self.alternaBotaoCancelarUber()
                                                })
                                                
                                            })
                                            
                                            alert.addAction(cancelAction)
                                            alert.addAction(confirmAction)
                                            self.present(alert, animated: true, completion: nil)
                                            
                                        }
                                    }
                                }
                            }
                        })
                        
                    } else {
                        print("Endereco nao digitado!")
                    }
                }
                
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissKeyboard()
    }
    
    private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return false
    }
    
}
