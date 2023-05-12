from flask import Flask, jsonify
import requests

app = Flask(__name__)

@app.route('/')
def scrape_and_serve():
    url = "https://nfs.faireconomy.media/ff_calendar_thisweek.json?"
    response = requests.get(url)
    data = response.json()

    # Filter the data for high impact events and for events in the USD or EUR countries
    filtered_data = [event for event in data if event.get('impact') == 'High' and event.get('country') in ['USD', 'EUR']]

    return jsonify(filtered_data)

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
