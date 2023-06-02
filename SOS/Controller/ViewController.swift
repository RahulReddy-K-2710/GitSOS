//
//  ViewController.swift
//  SOS
//
//  Created by Roja on 10/11/22.
//

import UIKit
import CoreLocation
import Contacts
import ContactsUI
import MessageUI

class ViewController: UIViewController {
    
//MARK: Properties.
    var manager = CLLocationManager()
    var geocoder = CLGeocoder()
    var delegate: CLLocationManagerDelegate?
    var selectedContact: ContactModel?
    var message: String?
    
// MARK: IBOutlets.
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sosButton: UIButton!
    @IBOutlet weak var locationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupLocation()
        //Add Right Navigation Bar Button Item here.
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTap))
    }
    //Set up Location.
    private func setupLocation() {
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }
    //Add CNContactPickerViewController and its delegate fuction.
    @objc func didTap() {
        let vc = CNContactPickerViewController()
        vc.delegate = self
        present(vc, animated: true)
        
    }
    
// MARK: IBActions.
    @IBAction func sosButtonTapped(_ sender: Any) {
        activityIndicator.startAnimating()
        manager.startUpdatingLocation()
    }
}

// MARK: CLLocationManager Delegate functions.
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !locations.isEmpty {
            if let location = locations.first {
                //Change the code using GeoCoder .
                geocoder.reverseGeocodeLocation(location) { placemarks, error in
                    if let placemarks = placemarks {
                        if !placemarks.isEmpty {
                            // Identify the placemarks here.
                            if let placemarks = placemarks.first {
                                self.activityIndicator.stopAnimating()
                                //Configer the data to UI.
                                self.locationLabel.text = "Location: \n\(placemarks.name ?? ""), \(placemarks.locality ?? ""), \(placemarks.subLocality ?? ""), \(placemarks.postalCode ?? "")"
                                // Add the Address to message.
                                self.message = "Latitude: \(location.coordinate.latitude), Longitude: \(location.coordinate.longitude), Address: \(placemarks.name ?? ""), \(placemarks.locality ?? ""), \(placemarks.subLocality ?? ""), \(placemarks.postalCode ?? "")"
                            }
                        }
                    }
                }
            }
        }
    }
}

//MARK: CNContactPickerDelegate, CNContactViewController Delegate Function.
extension ViewController: CNContactPickerDelegate, CNContactViewControllerDelegate {
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        var phoneNumbers = [String]()
        let name = contact.givenName + " " + contact.familyName
        for phoneNumber in contact.phoneNumbers {
            phoneNumbers.append(phoneNumber.value.stringValue)
        }
        let model = ContactModel(name: name, phoneNumbers: phoneNumbers)
        self.selectedContact = model
        //Load the SMS.
        sendSMS()
    }
}

//MARK: MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate.
extension ViewController: MFMessageComposeViewControllerDelegate, UINavigationControllerDelegate {
    func sendSMS() {
        if MFMessageComposeViewController.canSendText() {
            let vc = MFMessageComposeViewController()
            vc.body = message
            vc.recipients = selectedContact?.phoneNumbers
            vc.delegate = self
            present(vc, animated: true)
        }
    }
    //MessageComposeResult/ Fallied, Sent, Cancelled.
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result) {
        case .cancelled:
            dismiss(animated: true, completion: nil)
        case .failed:
            let vc = UIAlertController(title: "SOS", message: "Could not send SMS", preferredStyle: .alert)
            let actin = UIAlertAction(title: "Okay", style: .default)
            vc.addAction(actin)
            present(vc, animated: true)
            dismiss(animated: true, completion: nil)
        case .sent:
            let vc = UIAlertController(title: "SOS", message: "SMS sent successfully", preferredStyle: .alert)
            let actin = UIAlertAction(title: "Okay", style: .default)
            vc.addAction(actin)
            present(vc, animated: true)
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }
}
