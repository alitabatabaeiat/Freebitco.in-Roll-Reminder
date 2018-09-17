//
//  ViewController.swift
//  Freebitco.in Roll Reminder
//
//  Created by Ali Tabatabaei on 9/13/18.
//  Copyright © 2018 Ali Tabatabaei. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UNUserNotificationCenterDelegate {

    @IBOutlet weak var accountsTableView: UITableView!

    var isGrantedNotificationAccess = false
    var accounts = [Account]()
    var accountsTimeRemainingTillNextRoll = [Int]()
    var timer:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.badge,.sound]) { (granted, error) in
            self.isGrantedNotificationAccess = granted
            if !granted {
                //add alert to complain to user
            }
        }
        
        accountsTableView.delegate = self
        accountsTableView.dataSource = self
        
        setTimer()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        fetchAllAccounts()
    }
    
    @IBAction func addPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "addOrEditAccountSegue", sender: nil)
    }
    
    @IBAction func rollLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .ended {
            let location = sender.location(in: accountsTableView)
            let indexPath = accountsTableView.indexPathForRow(at: location)!
            let cell = self.accountsTableView.cellForRow(at: indexPath) as! AccountTableViewCell
            let button = cell.rollButton!
            let frame = cell.convert(button.frame, to: accountsTableView)
            if frame.contains(location) {
                setNextRollTimeDialog(for: button)
            }
            
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier === "addOrEditAccountSegue" {
//            if let destination = segue.destination as? AccountViewController {
//
//            }
//        }
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 106.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = accountsTableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath) as! AccountTableViewCell
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rollLongPress(_:)))
        
        cell.rollButton.addGestureRecognizer(longPressRecognizer)
        cell.setAccount(accounts[indexPath.row])
        cell.rollButton.tag = indexPath.row
        cell.rollButton.addTarget(self, action: #selector(rollPressed(_:)), for: .touchUpInside)
        return cell
    }
    
    @objc func rollPressed(_ sender: UIButton) {
        let date = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        roll(with: sender, nextRollAt: date)
    }
    
    @objc func updateRollButtons() {
        var rolledAccountFound = false
        for i in 0..<accounts.count {
            if let cell = accountsTableView.cellForRow(at: IndexPath(row: i, section: 0)) as? AccountTableViewCell {
                if let next_roll_date = accounts[i].next_roll_date {
                    let timeInterval = next_roll_date.timeIntervalSince(Date())
                    let seconds = Int(timeInterval)
                    if seconds > 0 {
                        rolledAccountFound = true
                        cell.rollButton.isEnabled = false
                        cell.rollButton.setTitle(timeString(time: timeInterval), for: .disabled)
                    } else {
                        cell.rollButton.isEnabled = true
                        cell.rollButton.setTitle("Roll", for: .normal)
                    }
                }
            }
        }
        if !rolledAccountFound {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let action = response.actionIdentifier
        let request = response.notification.request
        let accountIndex = Int(request.identifier.split(separator: ".")[1])
        if action == "roll.action" {
            let cell = accountsTableView.cellForRow(at: IndexPath(row: accountIndex!, section: 0)) as! AccountTableViewCell
            rollPressed(cell.rollButton)
        } else if action == "stop.action" {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
        }
        completionHandler()
    }
    
    func fetchAllAccounts() {
        let fetchRequest:NSFetchRequest<Account> = Account.fetchRequest()
        
        do {
            accounts = try context.fetch(fetchRequest) as [Account]
            accountsTableView.reloadData()
        } catch {
            let alert = UIAlertController(title: "Error", message: "Something went wrong... Please try again...", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try again!", style: .default, handler: { action in self.fetchAllAccounts() }))
            alert.present(self, animated: true, completion: nil)
        }
    }
    
    func roll(with button: UIButton, nextRollAt date: Date) {
        if isGrantedNotificationAccess {
            let account = accounts[button.tag]
            account.next_roll_date = date
            
            setTimer()
            
            createNotification(for: button.tag, at: date)
            
            let winAmount:Int32 = 30
            account.balance += winAmount
            if let referer = account.referer {
                referer.balance += winAmount / 2
            }
            do {
                try context.save()
                accountsTableView.reloadData()
            } catch {
                print("save record failed")
            }
            button.isEnabled = false
        }
    }
    
    func createNotification(for index: Int, at date: Date) {
        let account = accounts[index]
        let content = UNMutableNotificationContent()
        content.title = account.name!
        content.body = "Time to roll"
        content.subtitle = account.email!
        content.categoryIdentifier = "roll.category"
        content.sound = UNNotificationSound.default()
        
        let formattedDate = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: formattedDate, repeats: false)
        addNotification(trigger: trigger, content: content, identifier: "acoount.\(index)")
    }
    
    func setNextRollTimeDialog(for button: UIButton) {
        let alertController = UIAlertController(title: "Next Roll", message: "Enter Remaining minutes to your next roll", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default) { (_) in
            
            let minutes = alertController.textFields![0].text!
            
            let date = Calendar.current.date(byAdding: .minute, value: Int(minutes)!, to: Date())!
            self.roll(with: button, nextRollAt: date)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter Minutes"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func addNotification(trigger: UNNotificationTrigger?, content: UNMutableNotificationContent, identifier: String){
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request){
            (error) in
            if let err = error {
                print("error adding notification:\(err.localizedDescription)")
            }
        }
    }
    
    func setTimer() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateRollButtons), userInfo: nil, repeats: true)
        }
    }
    
    func timeString(time: TimeInterval) -> String {
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }

}

