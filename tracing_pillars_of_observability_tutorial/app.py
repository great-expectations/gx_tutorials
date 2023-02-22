from flask import Flask
import requests

from opentelemetry import trace
from opentelemetry.exporter.jaeger.thrift import JaegerExporter
from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

trace.set_tracer_provider(
TracerProvider(
        resource=Resource.create({SERVICE_NAME: "first-jaeger-tracing-service"})
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

@app.route("/")
def index():
    with tracer.start_as_current_span('index'):
        return "Hello Tracing!"


@app.route("/alpacas")
def alpacas():
    with tracer.start_as_current_span("alpacas"):
        with tracer.start_as_current_span("authn") as child:
            carrier = {}
            TraceContextTextMapPropagator().inject(carrier)
            header = {"traceparent": carrier["traceparent"]}
            r = requests.get('http://localhost:5001/authn', headers=header)

        return "Alpacas you own"


if __name__ == "__main__":
    app.run(debug=True)
