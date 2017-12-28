//
//  ViewController.swift
//  Uber
//
//  Created by Bruno Lopes de Mello on 09/12/2017.
//  Copyright © 2017 Bruno Lopes de Mello. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let autenticacao = Auth.auth()
        
        /*
        do {
            try autenticacao.signOut()
        } catch let erro {
            print("Erro: \(erro.localizedDescription)")
        }
        */
        
        //verifica o tempo todo se o usuario foi autenticado
        //independente da view
        autenticacao.addStateDidChangeListener { (auth, user) in
            
            if user != nil {
                
                let database = Database.database().reference()
                let usuarios = database.child("usuarios").child((user?.uid)!)
                
                usuarios.observeSingleEvent(of: DataEventType.value, with: { (snapshot) in
                    
                    print(snapshot)
                    let dados = snapshot.value as? NSDictionary
                    let tipoUsuario = dados!["tipo"] as! String
                    print("Tipo do usuario: " + tipoUsuario)
                    
                    if tipoUsuario == "passageiro" {
                        self.performSegue(withIdentifier: "segueLoginPrincipalPassageiro", sender: nil)
                    } else {
                        self.performSegue(withIdentifier: "segueLoginPrincipalMotorista", sender: nil)
                    }
                })
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

