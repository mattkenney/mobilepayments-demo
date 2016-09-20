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
    
    // Apple Pay Merchant Identifier
    fileprivate let ApplePayMerchantID = "merchant.com.beanstream.apbeanstream"
    
    // Beanstream Supported Payment Networks for Apple Pay
    fileprivate let SupportedPaymentNetworks = [PKPaymentNetwork.visa, PKPaymentNetwork.masterCard, PKPaymentNetwork.amex]
    
    fileprivate var paymentButton: PKPaymentButton!
    fileprivate var paymentAmount: NSDecimalNumber!

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
        /*
        if !PKPaymentAuthorizationViewController.canMakePaymentsUsingNetworks(supportedNetworks) {
            // Let user know they can not continue with an Apple Pay based transaction... 
            // Offer a Beanstream PayForm option instead!!! ;-)
            print("Apple Pay not available!")
            return
        }
         */
        
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
            "payment-method": "apple-pay",
            "apple-wallet": [
                "payment-token": b64TokenStr,
                "apple-pay-merchant-id": ApplePayMerchantID
            ]
        ] as [String : Any]

        print("payment parameters: \(parameters)")
        
        let hud = MBProgressHUD.showAdded(to: self.view, animated: true)

        //
        // validate(): 
        // Automatically validates status code within 200...299 range, and that the Content-Type header
        // of the response matches the Accept header of the request, if one is provided.
        //
        Alamofire.request("http://10.240.9.64:8080/process-payment", method: .post, parameters: parameters)
            .validate()
            .responseJSON { response in
                
                var status = "Payment was not processed"

                switch response.result {
                case .success:
                    print(response.data)     // server data
                    print(response.result)   // result of response serialization
                    
                    if let JSON = response.result.value {
                        print("JSON: \(JSON)")
                    }
                    
                    status = "Payment processed successfully"
                    completion(.success)
                    
                case .failure(let error):
                    print("process transaction request error: \(error)")
                    completion(.failure)
                }
                
                hud.hide(animated: true)
                
                let alert = UIAlertController.init(title: "Mobile Pay Demo", message: status, preferredStyle: .alert)
                self.present(alert, animated: true, completion: nil)
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
