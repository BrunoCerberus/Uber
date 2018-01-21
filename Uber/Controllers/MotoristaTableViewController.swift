//
//  MotoristaTableViewController.swift
//  Uber
//
//  Created by Bruno Lopes de Mello on 25/12/2017.
//  Copyright © 2017 Bruno Lopes de Mello. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class MotoristaTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    var listaRequisicoes: [DataSnapshot] = []
    var gerenciadorLocalizacao = CLLocationManager()
    var localMotorista = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //configurar localizacao do motorista
        self.gerenciadorLocalizacao.delegate = self
        self.gerenciadorLocalizacao.desiredAccuracy = kCLLocationAccuracyBest
        self.gerenciadorLocalizacao.requestWhenInUseAuthorization()
        self.gerenciadorLocalizacao.startUpdatingLocation()
        
        //configura o banco de dados
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        
        //recuperar requisicoes
        requisicoes.observe(.value) { (snapshot) in
            
            self.listaRequisicoes.removeAll()
            if snapshot.value != nil {
                for filho in snapshot.children {
                    
                    self.listaRequisicoes.append(filho as! DataSnapshot)

                }
            }
            self.tableView.reloadData()
        }
        
        //Limpa requisicao caso o usuario cancele
        requisicoes.observe(.childRemoved) { (snapshot) in
            
            var indice = 0
            
            for requisicao in self.listaRequisicoes {
                if requisicao.key == snapshot.key {
                    self.listaRequisicoes.remove(at: indice)
                }
                indice += 1
            }
            self.tableView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.listaRequisicoes.count
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordenadas = manager.location?.coordinate {
            self.localMotorista = coordenadas
        }
        
        self.gerenciadorLocalizacao.stopUpdatingLocation()
    }
    
    
    @IBAction func deslogar(_ sender: Any) {
        self.dismiss(animated: true) {
            let autenticacao = Auth.auth()
            do {
                try autenticacao.signOut()
            }catch let erro {
                print("Erro: \(erro.localizedDescription)")
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseCell", for: indexPath)
        let snapshot = self.listaRequisicoes[indexPath.row]
        
        if let dados = snapshot.value as? [String: Any] {
            
            if let latPassageiro = dados["latitude"] as? Double {
                if let lonPassageiro = dados["longitude"] as? Double {
                    
                    //calcular a distancia entre dois pontos
                    let motoristaLocation = CLLocation(latitude: self.localMotorista.latitude, longitude: self.localMotorista.longitude)
                    let passageiroLocation = CLLocation(latitude: latPassageiro, longitude: lonPassageiro)
                    
                    //calculo
                    let distanciaMetros = motoristaLocation.distance(from: passageiroLocation)
                    let distanciaKm = distanciaMetros / 1000
                    let distanciaKmRounded = distanciaKm.rounded(toPlaces: 2)
                    
                    var requisicaoMotorista = ""
                    if let emailMotoristaR = dados["motoristaEmail"] as? String{
                        let autenticacao = Auth.auth()
                        if let emailM = autenticacao.currentUser?.email {
                            
                            if emailMotoristaR == emailM {
                                requisicaoMotorista = " {EM ANDAMENTO}"
                                if let status = dados["status"] as? String {
                                    if status == StatusCorrida.ViagemFinalizada.rawValue {
                                        requisicaoMotorista = " {FINALIZADA}"
                                    }
                                }
                            }
                        }
                        
                    }
                    
                    
                    if let nomePassageiro = dados["nome"] as? String {
                        cell.textLabel?.text = "\(nomePassageiro) \(requisicaoMotorista)"
                            cell.detailTextLabel?.text = "\(distanciaKmRounded) KM de distância"
                    }
                    
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let snapshot = self.listaRequisicoes[indexPath.row]
        self.performSegue(withIdentifier: "segueAceitarCorrida", sender: snapshot)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueAceitarCorrida" {
            if let controller = segue.destination as? ConfirmarRequisicaoViewController {
                if let snapshot = sender as? DataSnapshot {
                    if let dados = snapshot.value as? [String:Any] {
                        if let latPassageiro = dados["latitude"] as? Double {
                            if let lonPassageiro = dados["longitude"] as? Double {
                                if let nomePassageiro = dados["nome"] as? String {
                                    if let emailPassageiro = dados["email"] as? String {
                                        
                                        // Recupera os dados do Passageiro
                                        let localPassageiro = CLLocationCoordinate2D(latitude: latPassageiro, longitude: lonPassageiro)
                                        // Envia os dados para a próxima ViewController
                                        controller.nomePassageiro = nomePassageiro
                                        controller.emailPassageiro = emailPassageiro
                                        controller.localPassageiro = localPassageiro
                                        // Envia os dados do motorista
                                        controller.localMotorista = self.localMotorista
                                        
                                    }
                                }
                            }
                            
                        }
                        
                    }
                    
                }
            }
        }
    }
    
    
}
