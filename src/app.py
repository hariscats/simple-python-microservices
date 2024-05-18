from flask import Flask, jsonify, render_template, request
import socket
import os
import psutil
import requests
from datetime import datetime

app = Flask(__name__)

# Function to fetch hostname and IP
def fetch_details():
    try:
        hostname = socket.gethostname()
        host_ip = socket.gethostbyname(hostname)
        return hostname, host_ip
    except socket.error as e:
        return "Unknown", str(e)

# Function to fetch environment details
def fetch_env_details():
    return dict(os.environ)

# Function to fetch system information
def fetch_system_info():
    return {
        "cpu_percent": psutil.cpu_percent(interval=1),
        "memory_percent": psutil.virtual_memory().percent,
        "disk_percent": psutil.disk_usage('/').percent
    }

# Function to fetch a random joke
def fetch_random_joke():
    try:
        response = requests.get("https://official-joke-api.appspot.com/jokes/random", timeout=5)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        return {"error": str(e)}

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

@app.route("/health")
def health():
    return jsonify(
        status="UP"
    )

@app.route("/details")
def details():
    hostname, ip = fetch_details()
    return render_template('index.html', HOSTNAME=hostname, IP=ip)

@app.route("/env")
def env():
    env_vars = fetch_env_details()
    return jsonify(env_vars)

@app.route("/time")
def current_time():
    now = datetime.now()
    current_time = now.strftime("%Y-%m-%d %H:%M:%S")
    return jsonify(time=current_time)

@app.route("/network")
def network_details():
    hostname, ip = fetch_details()
    pod_ip = os.getenv('POD_IP', 'Not running in Kubernetes')
    node_name = os.getenv('NODE_NAME', 'Not running in Kubernetes')
    return jsonify(
        hostname=hostname,
        host_ip=ip,
        pod_ip=pod_ip,
        node_name=node_name
    )

@app.route("/system-info")
def system_info():
    sys_info = fetch_system_info()
    return jsonify(sys_info)

@app.route("/random-joke")
def random_joke():
    joke = fetch_random_joke()
    return jsonify(joke)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
