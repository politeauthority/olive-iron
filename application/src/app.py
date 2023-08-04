#!/usr/bin/env python
"""
    Hello Graylog

"""
import logging
from logging.config import dictConfig

from flask import Flask, request

dictConfig({
    'version': 1,
    'formatters': {'default': {
        'format': '[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    }},
    'handlers': {'wsgi': {
        'class': 'logging.StreamHandler',
        'stream': 'ext://flask.logging.wsgi_errors_stream',
        'formatter': 'default'
    }},
    'root': {
        'level': 'INFO',
        'handlers': ['wsgi']
    }
})

logger = logging.getLogger(__name__)
logger.propagate = True
app = Flask(__name__)
app.config.update(DEBUG=True)
app.debugger = False



@app.before_request
def before_request():
    """Before we route the request log some info about the request"""
    logging.info(
        "[Request]\tpath: %s |\t method: %s" % (
            request.path,
            request.method))
    return

@app.route("/")
def index():
    the_doc = "<!DOCTYPE html><html><head><title>Hello Graylog!</title></head><body>Hello Graylog, my name is Alix Fullerton!</body></html>"
    return the_doc, 200

@app.route("/healthz")
def healthz():
    return "👍", 200

# Development Runner
if __name__ == "__main__":
    logging.info("Starting develop webserver")
    app.run(host='0.0.0.0', port=80)

# Production Runner
if __name__ != "__main__":
    gunicorn_logger = logging.getLogger("gunicorn.debug")
    logging.info("Starting production webserver")
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)
    app.config['DEBUG'] = True


# End File: cver/src/cver/api/app.py
