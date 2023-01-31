from random import randint
from flask import Flask

from prometheus_client import start_http_server
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.metrics import get_meter_provider, set_meter_provider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.view import ExplicitBucketHistogramAggregation, View


# Start Prometheus client
start_http_server(port=8000, addr='0.0.0.0')
# Exporter to export metrics to Prometheus
prefix = "FlaskPrefix"
reader = PrometheusMetricReader(prefix)
# Meter is responsible for creating and recording metrics
provider = MeterProvider(
  metric_readers=[reader],
  views=[View(
    instrument_name="*",
    aggregation=ExplicitBucketHistogramAggregation(
      (1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
    ))],
)
set_meter_provider(provider)
meter = get_meter_provider().get_meter("myapp", "0.1.2")

# Create a counter
counter = meter.create_counter(
    name="requests",
    description="The number of requests the app has had"
)


dicevalue = meter.create_histogram(
  name="dice_value",
  unit="s",
  description="Value of the dice rolls"
)

# Labels can be used to easily identify metrics and add futher fields to filter by
labels = {"environment": "testing"}

app = Flask(__name__)

@app.route("/rolldice")
def roll_dice():
  return str(do_roll())


@app.route("/rolldicecounter")
def roll_dice_counter():
  roll_value = do_roll()
  counter.add(1, labels)
  return str(roll_value)


@app.route("/rolldicehistogram")
def roll_dice_gauge():
  roll_value = do_roll() 
  dicevalue.record(roll_value, labels)
  return str(roll_value)


def do_roll():
  res = randint(1, 6)
  return res

