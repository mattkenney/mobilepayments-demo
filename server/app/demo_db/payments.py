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

import os
import sys
import enum
import logging
import datetime
from sqlalchemy import create_engine
from sqlalchemy import MetaData
from sqlalchemy import Column
from sqlalchemy import Integer
from sqlalchemy import Numeric
from sqlalchemy import Text
from sqlalchemy import DateTime
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.declarative import declarative_base


class PaymentMethod(enum.Enum):
    visa = "visa"
    mastercard = "mastercard"
    amex = "amex"
    discover = "discover"
    apple_pay = "apple-pay"
    android_pay = "android-pay"
    samsung_pay = "samsung-pay"


class PaymentStatus(enum.Enum):
    new = "new"
    authorized = "authorized"
    captured = "captured"
    voided = "voided"


##########################
# Data Model classes

Base = declarative_base()


class Payment(Base):
    __tablename__ = 'payments'
    id = Column(Integer, primary_key=True)
    bic_transaction_id = Column(Text, unique=True, nullable=True)
    payment_amount = Column(Numeric, nullable=False)
    payment_method = Column(PaymentMethod, nullable=False)
    payment_status = Column(PaymentStatus, nullable=False)
    created_date = Column(DateTime, default=datetime.datetime.utcnow)
    updated_date = Column(DateTime, onupdate=datetime.datetime.utcnow)


################
# Create and start up DB session factory

DATABASE_URL = os.environ.get('DATABASE_URL')

if DATABASE_URL is None:
    DATABASE_URL = 'sqlite:////tmp/mobilepay-demo.db'

try:
    if DATABASE_URL.startswith('postgres'):
        engine = create_engine(DATABASE_URL, client_encoding='utf8')
    else:
        engine = create_engine(DATABASE_URL, convert_unicode=True)

    meta = MetaData(bind=engine, reflect=True)
    DBSession = sessionmaker(bind=engine)

    # Create all tables in the engine. This is equivalent to "Create Table" statements in raw SQL.
    Base.metadata.create_all(engine)
except Exception as startup_e:
    print("fatal error", startup_e, file=sys.stderr)


################
# Data Access Classes

# The PaymentsDAO Object handles all interactions with the 'payments'data model/table.
class PaymentsDAO:

    logger = None

    def __init__(self):
        try:
            self.logger = logging.getLogger('mobilepay.demo')

            # test being able to create a DB session at start up
            session = DBSession()

        except NameError as e:
            print("Error: PaymentsDAO could not create DBSession!!", file=sys.stderr)
            if self.logger is not None:
                self.logger.exception(e)

        finally:
            if session is not None:
                session.close()

    def create_payment(self, payment_amount, payment_method):
        try:
            payment_amount = Numeric(payment_amount)

            payment = Payment(payment_amount=payment_amount,
                              payment_method=payment_method,
                              payment_status=PaymentStatus.new)

            session = DBSession()
            session.add(payment)
            session.commit()

            return {'success': True, 'id': payment.id}

        except Exception as e:
            session.rollback()

            extra = {
                'DatabaseException': 'Unexpected error in create_payment.',
                'Exception Detail': 'Unable to insert Payment with" +'
                                    ' payment_amount: ' + payment_amount +
                                    ' payment_method: ' + payment_method
            }

            self.logger.error(e, extra=extra)
            raise e

        finally:
            if session is not None:
                session.close()

    def update_payment(self, payment_id, bic_transaction_id, payment_status):
        try:
            session = DBSession()

            payment = session.query(Payment).filter(Payment.id == payment_id).first()

            if payment is None:
                return {'success': False, 'message': 'Payment record not found.'}

            payment.bic_transaction_id = bic_transaction_id
            payment.payment_status = payment_status
            session.commit()

            return {'success': True}

        except Exception as e:
            session.rollback()

            extra = {
                'DatabaseException': 'Unexpected error in update_payment.',
                'Exception Detail': 'Unable to update Payment with" +'
                                    ' payment_id: ' + payment_id +
                                    ' bic_transaction_id: ' + bic_transaction_id +
                                    ' payment_status: ' + payment_status
            }

            self.logger.error(e, extra=extra)
            raise e

        finally:
            if session is not None:
                session.close()
