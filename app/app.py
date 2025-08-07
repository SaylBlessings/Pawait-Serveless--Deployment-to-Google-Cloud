from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/analyze', methods=['POST'])
def analyze_text():
    """
    Accepts a JSON payload with text and returns a simple analysis.
    """
    try:
        data = request.get_json()
        if not data or 'text' not in data:
            return jsonify({"error": "Invalid input. 'text' field is required."}), 400

        text = data['text']
        word_count = len(text.split())
        character_count = len(text)

        response = {
            "original_text": text,
            "word_count": word_count,
            "character_count": character_count
        }

        return jsonify(response), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__': 
    app.run(host='0.0.0.0', port=8080)