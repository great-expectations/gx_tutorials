from flask import Flask, request

from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

trace.set_tracer_provider(
TracerProvider(
        resource=Resource.create({SERVICE_NAME: "authn_service"})
    )
)
tracer = trace.get_tracer(__name__)

# create a JaegerExporter
jaeger_exporter = JaegerExporter(
    # configure agent
    agent_host_name='localhost',
    agent_port=6831,
)

# Create a BatchSpanProcessor and add the exporter to it
span_processor = BatchSpanProcessor(jaeger_exporter)

# add to the tracer
trace.get_tracer_provider().add_span_processor(span_processor)

app = Flask(__name__)

@app.route("/authn")
def index():
    traceparent = get_header_from_flask_request(request, "traceparent")
    carrier = {"traceparent": traceparent[0]}   
    ctx = TraceContextTextMapPropagator().extract(carrier)
    with tracer.start_as_current_span("/authn", context=ctx):
        return '{"msg":"Serious Authentication"}'

def get_header_from_flask_request(request, key):
    return request.headers.get_all(key)

if __name__ == "__main__":
    app.run(port=5001, debug=True)
