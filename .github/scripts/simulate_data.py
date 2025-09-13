import os
import random
from datetime import datetime, timedelta, timezone
from influxdb_client import InfluxDBClient, Point, WriteOptions

# -----------------------------
# CONFIGURACIÓN (ENV o default)
# -----------------------------
INFLUX_URL = os.environ.get("INFLUXDB_URL")
INFLUX_TOKEN = os.environ.get("INFLUXDB_TOKEN")
INFLUX_ORG = os.environ.get("INFLUXDB_ORG")
INFLUX_BUCKET = os.environ.get("INFLUX_BUCKET", "datos_agua")

# Parámetros simulación
START_DATE = os.environ.get("START_DATE")  # formato "YYYY-MM-DD"
END_DATE = os.environ.get("END_DATE")      # formato "YYYY-MM-DD" (opcional)
NUM_SENSORS = int(os.environ.get("NUM_SENSORS", "4"))

# -----------------------------
# GENERADOR REALISTA (COLEGIO)
# -----------------------------
def generate_school_data(sensor_id: int, timestamp: datetime):
    hour = timestamp.hour
    minute = timestamp.minute
    weekday = timestamp.weekday()  # 0 = lunes, 6 = domingo

    # ----------- FLAGS DE EVENTOS ESPECIALES -----------
    weekend_event = (weekday in [5, 6]) and random.random() < 0.1
    turbidity_event = random.random() < 0.02

    # ----------- FLUJO BASE -----------
    base_flow = 0.2
    if weekday in [5, 6] and not weekend_event:
        base_flow = 0.2 + random.uniform(0, 0.3)
    else:
        if 8 <= hour < 9:
            base_flow = 5 + random.uniform(-0.5, 1.0)
        elif hour == 10 and 0 <= minute < 30:
            base_flow = 7 + random.uniform(-1, 1)
        elif 12 <= hour < 13:
            base_flow = 10 + random.uniform(-2, 2)
        elif hour == 15 and 0 <= minute < 30:
            base_flow = 6 + random.uniform(-1, 1)
        elif 16 <= hour < 18:
            base_flow = 4 + random.uniform(-1, 1)
        elif 19 <= hour or hour < 6:
            base_flow = 0.2 + random.uniform(0, 0.2)
        else:
            base_flow = 2 + random.uniform(-0.5, 0.5)

        if weekend_event:
            base_flow *= random.uniform(3, 6)

    # ----------- TURBIDEZ -----------
    turbidity = (base_flow * 0.4) + random.uniform(0, 1.0)
    if turbidity_event:
        turbidity += random.uniform(3, 8)

    # ----------- pH -----------
    ph = 7 + random.uniform(-0.2, 0.2)

    # ----------- CONDUCTIVIDAD -----------
    conductivity = 200 + random.uniform(-15, 15)

    return Point("water_sensors") \
        .tag("sensor_id", str(sensor_id)) \
        .field("turbidity", round(max(0, turbidity), 2)) \
        .field("ph", round(ph, 2)) \
        .field("conductivity", round(conductivity, 2)) \
        .field("flowRate", round(max(0, base_flow), 2)) \
        .time(timestamp)

# -----------------------------
# SIMULACIÓN
# -----------------------------
def run_generator(write_api):
    if START_DATE:
        start = datetime.fromisoformat(START_DATE).replace(tzinfo=timezone.utc)
        end = datetime.fromisoformat(END_DATE).replace(tzinfo=timezone.utc) if END_DATE else datetime.now(timezone.utc)

        current = start
        points = []

        while current <= end:
            for sensor_id in range(1, NUM_SENSORS + 1):
                points.append(generate_school_data(sensor_id, current))
            current += timedelta(minutes=15)

        # Escritura en un solo batch
        write_api.write(bucket=INFLUX_BUCKET, record=points)
        print(f"✅ Datos generados de {start} a {end} para {NUM_SENSORS} sensores "
              f"({len(points)} puntos)")
    else:
        # Solo un dato en tiempo real
        now = datetime.now(timezone.utc)
        points = [generate_school_data(sensor_id, now) for sensor_id in range(1, NUM_SENSORS + 1)]
        write_api.write(bucket=INFLUX_BUCKET, record=points)
        print(f"✅ Dato único generado para {NUM_SENSORS} sensores en {now}")

# -----------------------------
# MAIN
# -----------------------------
if __name__ == "__main__":
    with InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG) as influx_client:
        with influx_client.write_api(write_options=WriteOptions(batch_size=5000, flush_interval=10000)) as write_api:
            run_generator(write_api)
