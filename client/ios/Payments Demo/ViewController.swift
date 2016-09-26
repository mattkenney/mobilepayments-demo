//
//  ViewController.swift
//  Payments Demo
//
//  Created by Sven Resch on 2016-09-14.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
//

import UIKit
import PassKit
import Alamofire
import MBProgressHUD

class ViewController: UIViewController {
    
    @IBOutlet weak var purchaseTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var placeholderView: UIView!
    
    // Mobile Pay Demo Server
    fileprivate let DemoServerURLBase = "http://<your_demo_server_url>"
    
    // Apple Pay Merchant Identifier
    fileprivate let ApplePayMerchantID = "merchant.com.mycompany.app"
    
    // Beanstream Supported Payment Networks for Apple Pay
    fileprivate let SupportedPaymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard, PKPaymentNetwork.amex]
    
    fileprivate var paymentButton: PKPaymentButton!
    fileprivate var paymentAmount: NSDecimalNumber!
    fileprivate var alert: UIAlertController!
    fileprivate var hud: MBProgressHUD!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.paymentButton = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
        
        let pview = placeholderView
        pview?.addSubview(self.paymentButton)
        pview?.backgroundColor = UIColor.clear
        
        self.paymentButton.center = (pview?.convert((pview?.center)!, from: pview?.superview))!
        self.paymentButton.addTarget(self,
                                     action: #selector(ViewController.paymentButtonAction),
                                     for: .touchUpInside)
    }

    // MARK: - Custom action methods
    
    func paymentButtonAction() {
        // Check to make sure payments are supported.
        if !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: SupportedPaymentNetworks, capabilities: .capability3DS) {
            // Let user know they can not continue with an Apple Pay based transaction...
            let message = "Apple Pay not avialable on this device with the required card types!"
            let alert = UIAlertController.init(title: "Mobile Pay Demo", message: message, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (alert: UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            })
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let request = PKPaymentRequest()
        
        request.merchantIdentifier = ApplePayMerchantID
        request.supportedNetworks = SupportedPaymentNetworks
        request.merchantCapabilities = .capability3DS
        
        // Use a currency set to match your Beanstream Merchant Account
        request.countryCode = "CA" // "US"
        request.currencyCode = "CAD" // "USD"
        
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "1 Golden Egg", amount: NSDecimalNumber(string: "1.00"), type: .final),
            PKPaymentSummaryItem(label: "Shipping", amount: NSDecimalNumber(string: "0.05"), type: .final),
            PKPaymentSummaryItem(label: "GST Tax", amount: NSDecimalNumber(string: "0.07"), type: .final),
            PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: "1.12"), type: .final)
        ]
        
        self.paymentAmount = NSDecimalNumber(string: "1.12")
        
        let authVC = PKPaymentAuthorizationViewController(paymentRequest: request)
        authVC.delegate = self
        present(authVC, animated: true, completion: nil)
    }
}

extension ViewController: PKPaymentAuthorizationViewControllerDelegate {
    
    // Executes a process payment request on our Merchant Server
    func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        // Get payment data from the token and base64 encode it
        let token = payment.token
        let paymentData = token.paymentData
        let b64TokenStr = paymentData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        let transactionType = self.purchaseTypeSegmentedControl.selectedSegmentIndex == 0 ? "purchase" : "pre-auth"
        
        let parameters = [
            "amount": self.paymentAmount,
            "transaction-type": transactionType,
            "apple-wallet": [
                "payment-token": b64TokenStr,
                "apple-pay-merchant-id": ApplePayMerchantID
            ]
        ] as [String : Any]

        print("payment parameters: \(parameters)")
        
        self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)

        Alamofire.request(DemoServerURLBase + "/process-payment/apple-pay", method: .post, parameters: parameters, encoding: URLEncoding.httpBody).responseJSON {
            response in

            if let _ = self.hud {
                self.hud.hide(animated: true)
            }

            var successFlag = false
            var status = "Payment was not processed"
            var json: NSDictionary! = nil

            if let result = response.result.value {
                json = result as! NSDictionary
                print("JSON: \(json)")
            }

            let statusCode = response.response?.statusCode
                        
            if statusCode == 200 {
                successFlag = true
                status = "Payment processed successfully"
            }
            else {
                print("process transaction request error: \(statusCode)")
                if let _ = json, let message = json["message"] as! String? {
                    status = message
                }
                else if response.result.isFailure {
                    status = response.result.debugDescription
                }
            }
            
            self.alert = UIAlertController.init(title: "Mobile Pay Demo", message: status, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: { (alert: UIAlertAction) in
                self.dismiss(animated: true, completion: nil)
            })
            self.alert.addAction(okAction)
            
            if successFlag {
                completion(.success)
            }
            else {
                completion(.failure)
            }
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
        
        if let _ = self.hud {
            self.hud.hide(animated: true)
        }

        if let _ = self.alert {
            self.present(alert, animated: true, completion: nil)
            self.alert = nil
        }
    }
}
