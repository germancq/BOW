from flask import Flask, request, render_template, redirect, url_for
from flask_pymongo import PyMongo
from time import sleep, time
from pymongo import MongoClient
from . import celery_setup
from . import client_
from pathlib import Path
import datetime


app = Flask(__name__)

client = MongoClient()
app.db = client.flask_server

app.config.update(
    CELERY_BROKER_URL='pyamqp://guest@localhost//',
    CELERY_RESULT_BACKEND='rpc://'
)
#celery -A src.flask_server.celery worker      to start the daemon in separate console
celery = celery_setup.make_celery(app)

#mongo = PyMongo(app)
# connect to another MongoDB database on the same host
#app.config['MONGO_DBNAME'] = 'flask_server'
#mongo = PyMongo(app)

@app.route('/')
def hello_world():
    #The return value from a view function is automatically converted
    #into a response object for you. If the return value is a string
    #it's converted into a response object with the string as response body,
    #an 200 OK error code and a text/html mimetype
    return 'Hello, World!'

@app.route('/index', methods=['GET'])
def index():
    collection_docs = app.db.bootloader.find({})
    if (collection_docs is None) or (collection_docs.collection.count() == 0) :
        return 'No FPGAs'
    else :
        return render_template('index.html', documents=collection_docs)


@app.route('/<int:fpga_id>/delete',methods=['POST'])
def delete_entry(fpga_id):
    app.db.bootloader.delete_one({'_id': int(fpga_id)})
    return redirect(url_for('index'))

@app.route('/send_form', methods=['POST'])
def send_form():
    if request.form['submit'] == 'Add':
        return add()
    elif request.form['submit'] == 'Send':
        return send()
    else:
        return 'Error',404



#POST method, json data
@app.route('/add',methods=['POST'])
def add():
    request_json = request.get_json()
    fpga_id = None;
    setup_file = None;
    if request_json is None:
        fpga_id = request.form['id']
        setup_file = request.form['filename']
    else:
        fpga_id = request_json.get('id')
        setup_file = request_json.get('filename')

    if (fpga_id is None) or (setup_file is None):
        return 'parameter error',404
    #upsert the data
    app.db.bootloader.update_one(
        {
            '_id':fpga_id
        },
        {
            '$set':{
                    'setup_file': setup_file
                },
            '$currentDate': { 'update_at': True }
        },
        True
    )
    return redirect(url_for('index'))

@app.route('/boot',methods=['POST'])
def boot():
    request_json = request.get_json()
    fpga_id = request_json.get('id')
    port_nodemcu = request_json.get('port')
    ip_nodemcu = request.remote_addr
    #upsert the data
    app.db.bootloader.update_one(
        {
            '_id':fpga_id
        },
        {
            '$set':{
                    'port': port_nodemcu,
                    'ip': ip_nodemcu
                },
            '$currentDate': { 'update_at': True }
        },
        True
    )
    #get the object
    mongo_document = app.db.bootloader.find_one({'_id':int(fpga_id)})
    setup_file = mongo_document.get('setup_file')
    if setup_file is None:
        return 'ok, not File Loaded'
    else:
        #send the file
        url_fpga = 'http://'+str(ip_nodemcu)+':'+str(port_nodemcu)+'/data'
        send_to_fpga.delay(mongo_document['setup_file'],url_fpga)
        return 'file send'

@app.route('/send',methods=['POST'])
def send():
    request_json = request.get_json()
    fpga_id = None;
    filename = None;
    if request_json is None:
        fpga_id = request.form['id']
        filename = request.form['filename']
    else:
        fpga_id = request_json.get('id')
        filename = request_json.get('filename')
    #get the object
    mongo_document = app.db.bootloader.find_one({'_id':int(fpga_id)})
    if mongo_document is None:
        return 'No fpga_id',404

    if mongo_document.get('ip') is None or mongo_document.get('port') is None:
        return 'No Boot Loaded',404

    my_file = Path(filename)
    if not my_file.is_file():
        return 'file not exists', 404

    #send the file
    url_fpga = 'http://'+str(mongo_document.get('ip'))+':'+str(int(mongo_document.get('port')))+'/data'
    send_to_fpga.delay(filename,url_fpga)
    #client_.send_file_to_fpga(filename, url_fpga)
    return 'file send'



@celery.task()
def send_to_fpga(filename, url):
    sleep(1)
    client_.send_file_to_fpga(filename, url)
