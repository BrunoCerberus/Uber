//
//  SignInViewController.swift
//  Uber
//
//  Created by Bruno Lopes de Mello on 09/12/2017.
//  Copyright © 2017 Bruno Lopes de Mello. All rights reserved.
//

import UIKit
import Firebase

class SignInViewController: UIViewController, UITextFieldDelegate{
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var senhaLabel: UITextField!
    @IBOutlet weak var entrarButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func entrar(_ sender: Any) {
        
        let retorno = self.validarCampos()
        
        if retorno == "" {
            
            //Faz a autenticacao do usuario
            let autenticacao = Auth.auth()
            
            if let _email = self.emailField.text, let _senha = self.senhaLabel.text {
                
                autenticacao.signIn(withEmail: _email, password: _senha, completion: { (user, erro) in
                    
                    if erro == nil {
                        
                        /*
                            Valida se o usuário esta logado
                            Caso o usuário esteja logado, será redirecionado
                            automaticamente de acordo com o tipo de usuario
                            com evento criado na ViewController
                        */
                        
                        if user != nil {
                            
                            if let _userEmail = user?.email {
                                print("Usuario \(_userEmail) connected")
                                
                            }
                        }
                        
                    } else {
                        print("Erro ao autenticar o usuario")
                    }
                })
            }
            
        } else {
            print("O campo \(retorno) nao foi preenchido!")
        }
    }
    
    private func validarCampos() -> String {
        
        if (self.emailField.text?.isEmpty)! {
            return "E-Mail"
        } else if (self.senhaLabel.text?.isEmpty)! {
            return "Senha"
        }
        
        return ""
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.dismissKeyboard()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return false
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
