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
                self.performSegue(withIdentifier: "logado", sender: nil)
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

