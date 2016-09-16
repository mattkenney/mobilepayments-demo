#!/usr/bin/env python
#
# MIT License (MIT)
# Copyright (c) 2016 - Beanstream Internet Commerce, Inc. <http://beanstream.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
# to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of
# the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
# THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

import logging
import requests
from flask import Flask
from flask import request
from flask import jsonify
from werkzeug.exceptions import default_exceptions
from werkzeug.exceptions import HTTPException
from demo_db import payments

# Create the Server app
app = Flask(__name__)

# Setup a logger
logger = logging.getLogger('mobilepay.demo')


##########################
# ERROR/EXCEPTION HANDLING
#
# --> http://flask.pocoo.org/snippets/83/
# Creates a JSON-oriented Flask app.
#
# All error responses that you don't specifically
# manage yourself will have application/json content
# type, and will contain JSON like this (just an example):
#
# { "message": "405: Method Not Allowed" }


def make_json_error(ex):

    logger.exception(ex)
    response = jsonify(message=str(ex))
    response.status_code = (ex.code
                            if isinstance(ex, HTTPException)
                            else 500)
    return response


for code in default_exceptions.items():
        app.error_handler_spec[None][code] = make_json_error


##########################
# ROUTES

@app.route('/process-payment', methods=['POST'])
def process_payment():
    # Ensure that POST params were all passed in OK.
    payment_method = request.form.get('payment-method')

    if payment_method != 'apple-pay':
        return error400('Apple Pay payment method is required.')

    amount = request.form.get('amount')
    transaction_type = request.form.get('transaction-type')
    apple_wallet = request.form.get('apple-wallet')
    ap_merchant_id = apple_wallet.get('apple-pay-merchant-id')
    ap_token = apple_wallet.get('payment-token')

    if transaction_type != "purchase" and transaction_type != "pre-auth":
        transaction_type = None

    if amount is None \
            or transaction_type is None \
            or apple_wallet is None \
            or ap_merchant_id is None \
            or ap_token is None:

        return error400('Expected params not found.')

    # Create a new payment record in the local database.
    payment_dict = payments_dao.create_payment(
        payment_amount=amount,
        payment_method=payments.PaymentMethod.apple_pay
    )

    # Call on Beanstream process the payment.
    payload = {
        'amount': amount,
        'payment_method': 'apple_pay',
        "apple_pay": {
            "apple_merchant_id": ap_merchant_id,
            "payment_token": ap_token
        }
    }

    if transaction_type == 'pre-auth':
        payload['complete'] = False

    response = requests.post('https://www.beanstream.com/api/v1/payments', data=payload)
    response = response.json()

    bic_transaction_id = response.get('id')

    # Update the payment record to include the Beanstream Transaction ID
    # and a status to indicate payment was captured.
    response = payments_dao.update_payment(
        payment_id=payment_dict.get('id'),
        bic_transaction_id=bic_transaction_id,
        payment_status=payments.PaymentStatus.captured
    )

    return response.json()


# HELPER FUNCTIONS

# Used for custom error handling
@app.errorhandler(400)
def error400(e):

    logger.warning(e)
    return jsonify(error=400, message=str(e)), 400


@app.errorhandler(Exception)
def error500(e):

    logger.exception(e)
    error_code = 500
    return jsonify(error=error_code, message=str(e)), error_code

# START SERVER

payments_dao = payments.PaymentsDAO()

if __name__ == '__main__':
    app.run(host='localhost', port=8080)
