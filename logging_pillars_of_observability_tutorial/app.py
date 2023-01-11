from typing import Any, MutableMapping

import structlog
from flask import Flask, request


def standard_field_adder(
    logger: structlog.types.WrappedLogger,
    method_name: str,
    event_dict: MutableMapping[str, Any],
):
    event_dict["env"] = "local"
    event_dict["service"] = "logging-tutorial"
    event_dict["user-agent"] = request.user_agent
    event_dict["ip"] = request.remote_addr
    event_dict["url"] = request.url
    event_dict["method"] = request.method
    return event_dict


structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        standard_field_adder,
        structlog.processors.JSONRenderer(),
    ]
)
log = structlog.get_logger()

app = Flask(__name__)


@app.route("/observability")
def observability():
    return "Hello, Observability"


@app.route("/stdout")
def stdout():
    print("Writing to stdout as a log message!")
    return "Basic Logging"


@app.route("/jsonlog")
def log_it_out():
    log.warning("One sweet JSON log")
    return "Logging to json logs"
