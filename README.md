<img src="http://www.beanstream.com/wp-content/uploads/2015/08/Beanstream-logo.png" />

# Mobile (ApplePay &amp; AndroidPay) Payments Demo Merchant Clients & Server

Copyright © 2016 Beanstream Internet Commerce, Inc.

# Client

THe iOS client project was built with XCode 7 and requires Swift 2.3.

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
$ cd mobilepay-demo/server
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
