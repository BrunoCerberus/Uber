//
//  SignUpViewController.swift
//  Uber
//
//  Created by Bruno Lopes de Mello on 09/12/2017.
//  Copyright © 2017 Bruno Lopes de Mello. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var nomeField: UITextField!
    @IBOutlet weak var senhaField: UITextField!
    @IBOutlet weak var confirmaSenhaField: UITextField!
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var cadastroButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cadastrar(_ sender: Any) {
        
        let retorno = self.validaCampos()
        
        if retorno == "" {
            
            if self.confirmaSenha(self.senhaField.text, self.confirmaSenhaField.text) {
                
                //cadastrar usuario no firebase
                let autenticacao = Auth.auth()
                
                if let _email = self.emailField.text, let _senha = self.senhaField.text, let _nome = self.nomeField.text {
                    
                    autenticacao.createUser(withEmail: _email, password: _senha, completion: { (user, erro) in
                        
                        if erro == nil {
                            print("Sucesso ao criar o usuario")
                            if user != nil {
                                
                                //Configura o database
                                let database = Database.database().reference()
                                let usuarios = database.child("usuarios")
                                
                                //Verifica tipo do usuario
                                var tipo = ""
                                if self.switch.isOn {
                                    tipo = "passageiro"
                                } else {
                                    tipo = "motorista"
                                }
                                
                                //Salvar no banco de dados os dados do usuario
                                let dadosUsuario = [
                                    "email" : _email,
                                    "nome" : _nome,
                                    "tipo" : tipo
                                ]
                                
                                print(dadosUsuario)
                                
                                //Salvar dados
                                usuarios.child((user?.uid)!).setValue(dadosUsuario)
                                
                                //self.performSegue(withIdentifier: "signUp", sender: nil)
                            }
                            
                        } else {
                            print("Erro ao criar o usuario")
                        }
                    })
                }
                
            } else {
                print("Senhas diferentes")
            }
            
        } else {
            print("O campo \(retorno) nao foi preenchido!")
        }
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
    
    private func validaCampos() -> String {
        
        if (self.emailField.text?.isEmpty)! {
            return "E-Mail"
        } else if (self.nomeField.text?.isEmpty)! {
            return "Nome"
        } else if (self.senhaField.text?.isEmpty)! {
            return "Senha"
        } else if (self.confirmaSenhaField.text?.isEmpty)! {
            return "Confirma Senha"
        }
        
        return ""
    }
    
    private func confirmaSenha(_ password: String?,_ confirmPassword: String?) -> Bool {
        if let _senha = password, let _confirmaSenha = confirmPassword {
            
            if _senha == _confirmaSenha {
                return true
            }
            
            return false
        }
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
