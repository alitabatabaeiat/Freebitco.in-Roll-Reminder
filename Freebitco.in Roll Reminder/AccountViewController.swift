//
//  AccountViewController.swift
//  Freebitco.in Roll Reminder
//
//  Created by Ali Tabatabaei on 9/13/18.
//  Copyright © 2018 Ali Tabatabaei. All rights reserved.
//

import UIKit
import CoreData
import Validator

class AccountViewController: UIViewController, UIPickerViewDelegate,  UIPickerViewDataSource {

    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var nameTxt: UITextField!
    @IBOutlet weak var balanceTxt: UITextField!
    @IBOutlet weak var rewardPointsTxt: UITextField!
    @IBOutlet weak var refererPicker: UIPickerView!
    
    var accounts = [Account]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchAllAccounts()
        
        refererPicker.delegate = self
        refererPicker.dataSource = self
    }
    

    @IBAction func cancelPresed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func savePressed(_ sender: UIBarButtonItem) {
        if let email = emailTxt.text {
            if !isValidEmail(email) {
                return
            }
        }
        
        let account = Account(context: context)
        account.email = emailTxt.text
        account.name = nameTxt.text
        account.balance = Int32(balanceTxt.text!)!
        account.reward_points = Int32(rewardPointsTxt.text!)!
        account.next_roll_date = Date()
        let referer = refererPicker.selectedRow(inComponent: 0)
        account.referer = referer != 0 ? accounts[referer - 1] : nil
        
        do {
            try context.save()
        } catch {
            print("save record failed")
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return accounts.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return row == 0 ? "" : accounts[row - 1].email
    }
    
    func fetchAllAccounts() {
        let fetchRequest:NSFetchRequest<Account> = Account.fetchRequest()
        
        do {
            accounts = try context.fetch(fetchRequest) as [Account]
        } catch {
            let alert = UIAlertController(title: "Error", message: "Something went wrong... Please try again...", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try again!", style: .default, handler: { action in self.fetchAllAccounts() }))
            alert.present(self, animated: true, completion: nil)
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRule = ValidationRulePattern(pattern: EmailValidationPattern.standard, error: ValidationError(message: "Email is not valid!"))
        let result = email.validate(rule: emailRule)
        switch result {
        case .valid:
            print("valid")
            return true
        case .invalid(let failures):
            let message = (failures.compactMap { $0 as? ValidationError }.map { $0.message }).joined(separator: "")
            print("invalid!", message)
            return false
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
