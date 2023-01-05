from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def webhook():
    # Run the Python script
    subprocess.run(["python", r"C:\Users\your_user\Downloads\plot_history_improved.py"])
    return 'Success'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
