import os
from src import flask_server
import unittest
import tempfile
import json
from pymongo import MongoClient
from time import sleep
import datetime

client = MongoClient()
db = client.test

class FlaskServerTestCase(unittest.TestCase):

    def setUp(self):
        flask_server.app.db = db
        flask_server.app.testing = True
        self.app = flask_server.app.test_client()

    def tearDown(self):
        db.bootloader.drop()

    def test_hello(self):
        resp = self.app.get('/')
        assert b'Hello, World!' in resp.data
        self.assertEqual(resp.status_code, 200)

    def test_empty_index(self):
        resp = self.app.get('/index')
        assert b'No FPGAs' in resp.data
        self.assertEqual(resp.status_code, 200)

    def test_add(self):
        uut_document = {'id':0, 'filename':'prueba'}
        response=self.app.post('/add',
                       data=json.dumps(uut_document),
                       content_type='application/json')
        self.assertEqual(response.status_code, 302)#302 -> redirect
        doc = db.bootloader.find_one({'_id':0})
        self.assertEqual(doc['_id'],uut_document['id'])
        self.assertEqual(doc['setup_file'],uut_document['filename'])
        self.assertNotEqual(doc['update_at'],0)

    def test_add_404(self):
        uut_document = {'id':0}
        response=self.app.post('/add',
                       data=json.dumps(uut_document),
                       content_type='application/json')
        self.assertEqual(response.status_code, 404)

    def test_boot(self):
        db.bootloader.insert_one({'_id':0,'setup_file':'prueba', 'update_at':datetime.datetime.utcnow()})
        doc_before = db.bootloader.find_one({'_id':0})
        sleep(1)
        uut_document = {'id':0,'port':6700}
        response=self.app.post('/boot',
                       data=json.dumps(uut_document),
                       content_type='application/json')
        assert b'file send' in response.data
        self.assertEqual(response.status_code, 200)
        doc_after = db.bootloader.find_one({'_id':0})
        self.assertEqual(doc_after['_id'],0)
        self.assertEqual(doc_after['port'],uut_document['port'])
        self.assertEqual(doc_after['setup_file'],'prueba')
        self.assertNotEqual(doc_before['update_at'],doc_after['update_at'])


    def test_index(self):
        db.bootloader.insert_one({'_id':0,'filename':'prueba'})
        resp = self.app.get('/index')
        collection_docs = db.bootloader.find({}).collection
        doc = db.bootloader.find_one({'_id':0})
        self.assertEqual(doc['_id'],0)
        self.assertNotEqual(collection_docs.count(),0)
        assert b'Flask_Server' in resp.data
        self.assertEqual(resp.status_code, 200)

    def test_send_Not_Id(self):
        uut_document = {'id':0, 'filename':'prueba'}
        response=self.app.post('/send',
                       data=json.dumps(uut_document),
                       content_type='application/json')
        assert b'No fpga_id' in response.data
        self.assertEqual(response.status_code, 404)

    def test_send_not_Boot(self):
        uut_document = {'id':0, 'filename':'prueba'}
        db.bootloader.insert_one({'_id':0,'setup_file':'prueba'})
        response=self.app.post('/send',
                       data=json.dumps(uut_document),
                       content_type='application/json')
        assert b'No Boot Loaded' in response.data
        self.assertEqual(response.status_code, 404)

    def test_send_Not_file(self):
        uut_document = {'id':0, 'filename':'prueba'}
        db.bootloader.insert_one({'_id':0,'setup_file':'prueba', 'ip':'10.10.01.10','port':9878})
        response=self.app.post('/send',
                       data=json.dumps(uut_document),
                       content_type='application/json')
        assert b'file not exists' in response.data
        self.assertEqual(response.status_code, 404)

    def test_send(self):
        uut_document = {'id':0, 'filename':'/home/german/flask_server/setup.py'}
        db.bootloader.insert_one({'_id':0,
                                  'filename':'/home/german/flask_server/setup.py',
                                  'ip':'10.10.01.10',
                                  'port':9878})
        response=self.app.post('/send',
                       data=json.dumps(uut_document),
                       content_type='application/json')
        assert b'file send' in response.data
        self.assertEqual(response.status_code, 200)

    def test_delete_entry(self):
        db.bootloader.insert_one({'_id':0,'setup_file':'prueba'})
        doc_before = db.bootloader.find_one({'_id':0})
        self.assertNotEqual(doc_before,None)
        response = self.app.post('/0/delete')
        self.assertEqual(response.status_code,302)
        doc_after = db.bootloader.find_one({'_id':0})
        self.assertEqual(doc_after,None)

if __name__ == '__main__':
    unittest.main()
