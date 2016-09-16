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
    private let ApplePayMerchantID = "merchant.com.beanstream.apbeanstream"
    
    // Beanstream Supported Payment Networks for Apple Pay
    private let SupportedPaymentNetworks = [PKPaymentNetworkVisa, PKPaymentNetworkMasterCard, PKPaymentNetworkAmex]
    
    private var paymentButton: PKPaymentButton!
    private var paymentAmount: NSDecimalNumber!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.paymentButton = PKPaymentButton(paymentButtonType: .Buy, paymentButtonStyle: .Black)
        
        let pview = placeholderView
        pview.addSubview(self.paymentButton)
        pview.backgroundColor = UIColor.clearColor()
        
        self.paymentButton.center = pview.convertPoint(pview.center, fromView: pview.superview)
        self.paymentButton.addTarget(self,
                                     action: #selector(ViewController.paymentButtonAction),
                                     forControlEvents: .TouchUpInside)
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
        request.merchantCapabilities = .Capability3DS
        
        // Use a currency set to match your Beanstream Merchant Account
        request.countryCode = "CA" // "US"
        request.currencyCode = "CAD" // "USD"
        
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "1 Golden Egg", amount: NSDecimalNumber(double: 1.00), type: .Final),
            PKPaymentSummaryItem(label: "Shipping", amount: NSDecimalNumber(double: 0.05), type: .Final),
            PKPaymentSummaryItem(label: "GST Tax", amount: NSDecimalNumber(double: 0.07), type: .Final),
            PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(double: 1.12), type: .Final)
        ]
        
        self.paymentAmount = NSDecimalNumber(double: 1.12)
        
        let authVC = PKPaymentAuthorizationViewController(paymentRequest: request)
        authVC.delegate = self
        presentViewController(authVC, animated: true, completion: nil)
    }
}

extension ViewController: PKPaymentAuthorizationViewControllerDelegate {
    
    // Executes a process payment request on our Merchant Server
    func paymentAuthorizationViewController(controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: (PKPaymentAuthorizationStatus) -> Void) {
        print(payment.token)
        
        // Get payment data from the token and base64 encode it
        let token = payment.token
        let paymentData = token.paymentData
        let b64TokenStr = paymentData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        
        let transactionType = self.purchaseTypeSegmentedControl.selectedSegmentIndex == 0 ? "purchase" : "pre-auth"
        
        let parameters = [
            "amount": self.paymentAmount,
            "transaction-type": transactionType,
            "payment-method": "apple-pay",
            "apple-wallet": [
                "payment-token": b64TokenStr,
                "apple-pay-merchant-id": ApplePayMerchantID
            ]
        ]
        
        let hud = MBProgressHUD.showHUDAddedTo(self.view, animated: true)

        //
        // validate(): 
        // Automatically validates status code within 200...299 range, and that the Content-Type header
        // of the response matches the Accept header of the request, if one is provided.
        //
        Alamofire.request(.POST, "http://10.240.9.64:8080/process-payment", parameters: parameters)
            .validate()
            .responseJSON { response in
                
                var status = "Payment was not processed"

                switch response.result {
                case .Success:
                    print(response.data)     // server data
                    print(response.result)   // result of response serialization
                    
                    if let JSON = response.result.value {
                        print("JSON: \(JSON)")
                    }
                    
                    status = "Payment processed successfully"
                    completion(.Success)
                    
                case .Failure(let error):
                    print("process transaction request error: \(error)")
                    completion(.Failure)
                }
                
                hud.hideAnimated(true)
                
                let alert = UIAlertController.init(title: "Mobile Pay Demo", message: status, preferredStyle: .Alert)
                self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func paymentAuthorizationViewControllerDidFinish(controller: PKPaymentAuthorizationViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
