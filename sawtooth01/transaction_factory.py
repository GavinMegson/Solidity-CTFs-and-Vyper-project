import hashlib
import secp256k1
import time
import requests
import json


# Sawtooth SDK
from sawtooth_sdk.protobuf.transaction_pb2 import Transaction
from sawtooth_sdk.protobuf.transaction_pb2 import TransactionHeader
from sawtooth_sdk.protobuf.batch_pb2 import Batch
from sawtooth_sdk.protobuf.batch_pb2 import BatchHeader
from sawtooth_sdk.protobuf.batch_pb2 import BatchList

from protobuf.payload_pb2 import *
import addressing

def _get_batcher_public_key(signer):
    return signer.pubkey.serialize().hex()


def _get_time():
    return int(time.time())


def _create_signer(private_key):
    signer = secp256k1.PrivateKey(privkey=bytes.fromhex(str(private_key)))
    return signer
    

class Txn_Factory():
    def create_project(self, args):
        ''' Creates a transaction that includes a create_project payload

            args: [password/signer, project_name]
        '''
        pass

    def create_task(self, args):
        ''' Creates a transaction that includes a create_task payload

            args: [password/signer, project_name, task_name, description]
        '''
        pass

    def progress_task(self, args):
        ''' Creates a transaction that includes a progress_task payload

            args: [password/signer, project_name, task_name]
        '''
        pass

    def edit_task(self, args):
        ''' Creates a transaction that includes a create_project payload

            args: [password/signer, project_name, task_name, description]
        '''
        pass

    def add_user(self, args):
        ''' Creates a transaction that includes an add_user payload

            args: [password/signer, project_name, password]
        '''
        pass


    def create_transaction(self, signer, payload_bytes):
        '''Bundles together a transaction that includes the given payload and is signed by given signer'''
        pass

    def create_batch(self, signer, txn):
        '''Bundles together a batch that includes txn and is signed by given signer'''
        pass


def send_it(batch_list_bytes):
    '''Sends batch to REST API where it'''
    pass

if __name__ == '__main__':
    txn_factory = Txn_Factory()

    args = sys.argv[1:]
    passcode = args[1]

    priv_key = hashlib.sha256(passcode.encode('utf-8')).hexdigest()
    args[1] = _create_signer(priv_key)
    # run desired function
    getattr(txn_factory, args[0])(args[1:])
