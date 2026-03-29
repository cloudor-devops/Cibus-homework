from flask import Flask, jsonify

app = Flask(__name__)


@app.route("/")
def root():
    return jsonify(service="task-app"), 200


@app.route("/healthz")
def health():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
