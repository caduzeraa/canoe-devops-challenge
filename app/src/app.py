from flask import Flask, jsonify, request
import time

app = Flask(__name__)

@app.route('/healthcheck', methods=['GET'])
def health_check():
    return jsonify({'healtchcheck': 'alive'}), 200

@app.route('/hello_world', methods=['GET'])
def hello_world():
    return jsonify({'message': 'Hello World!'}), 200

@app.route('/current_time', methods=['GET'])
def current_time():
    name = request.args.get('name')
    if name is not None and name != '':
        return jsonify({'timestamp': time.time(), "message": "Hello " + request.args.get('name')}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)