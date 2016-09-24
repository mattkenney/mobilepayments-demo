<img src="http://www.beanstream.com/wp-content/uploads/2015/08/Beanstream-logo.png" />

# Mobile (ApplePay &amp; AndroidPay) Payments Demo Merchant Clients & Server

Copyright © 2016 Beanstream Internet Commerce, Inc.

This repo contains a demo iOS client and a simplistic merchant server. The idea is that an iOS client will request that a payment be made using Apple Pay and that, if successful, then a resulting Apple Pay token will be transmitted to a merchant's server usually along with other info such as a customer identifier along with detailed sales/inventory data along with related shipping & billing addresses. This would generally be recorded on the merchants CRM, as an example, and then a request to process the payment using the Apple Pay token will be made to the Beanstream RESTful Payments API. Upon success or failure to process the payment, the merchants CRM would usually then be updated and then the end client receives a result.

Again this is a simpistic approach. A real system may be much more complex and, for example, may include a more sophsiticated message queue based infrastructure to help with high volume transaction processing.

# Client

The iOS client project was built with XCode 8 and requires Swift 3.0.

For details on how to develop Apple Pay enabled apps please visit:
- https://developer.apple.com/library/content/ApplePay_Guide/index.html#//apple_ref/doc/uid/TP40014764-CH1-SW1


# Server

The server project requires Python 3.

For local dev you can also use a SQLite DB by just setting (or omitting) the following default env var.
```bash
DATABASE_URL=sqlite:////tmp/mobilepay-demo.db
```

## Server Setup & Installation

* Execute a git clone command on this repo and in a terminal cd into the root project directory.
```bash
$ git clone https://github.com/beanstream/mobilepay-demo.git
$ cd mobilepay-demo/server/server-app
```
* Install virtualenv
```bash
$ [sudo] pip install virtualenv
```
* Create and/or Activate project environment
```bash
$ virtualenv -p python3 venv
$ source venv/bin/activate
```
* Install/update project dependencies
```bash
$ pip install -r requirements.txt
```

## Execution

* To run the flask app just for development only (not for production) just do this:
```bash
$ python server.py
```
