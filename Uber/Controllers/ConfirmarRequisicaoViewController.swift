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

class ConfirmarRequisicaoViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapa: MKMapView!
    
    
    var nomePassageiro = ""
    var emailPassageiro = ""
    var localPassageiro = CLLocationCoordinate2D()
    var localMotorista = CLLocationCoordinate2D()

    override func viewDidLoad() {
        super.viewDidLoad()

        //configurar a area inicial do mapa
        let regiao = MKCoordinateRegionMakeWithDistance(self.localPassageiro, 200, 200)
        self.mapa.setRegion(regiao, animated: true)
        
        //adiciona a anotacao para o passageiro
        let anotacaoPassageiro = MKPointAnnotation()
        anotacaoPassageiro.coordinate = self.localPassageiro
        anotacaoPassageiro.title = self.nomePassageiro
        mapa.addAnnotation(anotacaoPassageiro)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func aceitarCorrida(_ sender: Any) {
        
        //atualizar requisicao
        let database = Database.database().reference()
        let requisicoes = database.child("requisicoes")
        
        requisicoes.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassageiro).observeSingleEvent(of: .childAdded) { (snapshot) in
            
            let dadosMotorista = [
                "motoristaLatitude" : self.localMotorista.latitude,
                "motoristaLongitude": self.localMotorista.longitude
            ]
            
            snapshot.ref.updateChildValues(dadosMotorista)
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
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
