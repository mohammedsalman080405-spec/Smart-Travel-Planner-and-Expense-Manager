from decimal import Decimal, ROUND_HALF_UP


# ECB reference rates published on 30 October 2026:
# EUR 1 = USD 1.1172 and EUR 1 = INR 106.0840.
# This fixed reference snapshot keeps seeded/demo INR values deterministic.
USD_TO_INR = Decimal('106.0840') / Decimal('1.1172')
INR = 'INR'


def amount_in_inr(amount, currency='INR'):
    value = Decimal(str(amount or 0))
    code = (currency or INR).upper()
    if code == INR:
        converted = value
    elif code == 'USD':
        converted = value * USD_TO_INR
    else:
        raise ValueError(f'Unsupported currency for INR conversion: {code}')
    return converted.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
