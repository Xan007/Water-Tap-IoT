import os
from datetime import datetime, timezone
import pandas as pd
from influxdb_client import InfluxDBClient
from influxdb_client.client.warnings import MissingPivotFunction
import warnings
from supabase import create_client

# -----------------------------
# IGNORAR WARNINGS DE PIVOT
# -----------------------------
warnings.simplefilter("ignore", MissingPivotFunction)

# -----------------------------
# CONFIGURACIÓN (Variables de entorno)
# -----------------------------
INFLUX_URL = os.environ("INFLUXDB_URL")
INFLUX_TOKEN = os.environ.get("INFLUXDB_TOKEN")
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_KEY")
INFLUX_ORG = os.environ.get("INFLUXDB_ORG")

# -----------------------------
# CONEXIÓN A SUPABASE
# -----------------------------
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# -----------------------------
# CONEXIÓN A INFLUXDB
# -----------------------------
influx_client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)

# -----------------------------
# CONFIGURACIÓN DE SENSORES
# -----------------------------
SENSOR_IDS = [1, 2, 3, 4]

# -----------------------------
# FUNCIONES
# -----------------------------
def get_last_report(sensor_id: int):
    res = supabase.table("sensor_reports")\
        .select("to")\
        .eq("sensor_id", sensor_id)\
        .order("to", desc=True)\
        .limit(1).execute()
    
    if res.data and res.data[0]["to"]:
        return pd.to_datetime(res.data[0]["to"])
    return None

def fetch_influx_data(sensor_id: int, start: datetime, end: datetime):
    """
    Obtiene datos de InfluxDB para un sensor entre start y end.
    """
    query = f'''
    from(bucket: "datos_agua")
    |> range(start: {start.isoformat()}, stop: {end.isoformat()})
    |> filter(fn: (r) => r["_measurement"] == "water_sensors")
    |> filter(fn: (r) => r["sensor_id"] == "{sensor_id}")
    |> pivot(rowKey:["_time"], columnKey: ["_field"], valueColumn: "_value")
    |> keep(columns: ["_time", "sensor_id", "turbidity", "ph", "conductivity", "flowRate"])
    '''

    try:
        df = influx_client.query_api().query_data_frame(query)
    except Exception as e:
        print(f"Error consultando InfluxDB para sensor {sensor_id}: {e}")
        return pd.DataFrame()
    
    if df.empty:
        return pd.DataFrame()
    
    df.rename(columns={"_time": "timestamp"}, inplace=True)
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    return df

def calculate_stats(df: pd.DataFrame):
    stats = {}
    for col in ["turbidity", "ph", "conductivity", "flowRate"]:
        if col in df:
            series = df[col].fillna(0.0)
            stats[col] = {
                "min": float(series.min()),
                "max": float(series.max()),
                "avg": float(series.mean()),
                "q1": float(series.quantile(0.25)),
                "q3": float(series.quantile(0.75))
            }
    return stats

def calculate_hourly_samples(df: pd.DataFrame):
    if df.empty:
        return []
    
    df["hour"] = df["timestamp"].dt.hour
    samples = []
    
    for hour, group in df.groupby("hour"):
        sample = {"hour": f"{hour:02d}:00"}
        for col in ["turbidity", "ph", "conductivity", "flowRate"]:
            if col in group:
                sample[col] = float(group[col].mean())
        samples.append(sample)
    
    return samples

# -----------------------------
# ETL PRINCIPAL
# -----------------------------
def run_etl():
    now = datetime.now(timezone.utc)
    start_of_day = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
    
    for sensor_id in SENSOR_IDS:
        last_report_time = get_last_report(sensor_id)
        start_time = last_report_time or start_of_day
        
        df = fetch_influx_data(sensor_id, start_time, now)

        if df.empty:
            print(f"No hay datos para sensor {sensor_id} entre {start_time} y {now}")
            continue
        
        stats = calculate_stats(df)
        samples = calculate_hourly_samples(df)
        
        supabase.table("sensor_reports").insert({
            "from": start_time.isoformat(),
            "to": now.isoformat(),
            "sensor_id": sensor_id,
            "stats": stats,
            "samples": samples
        }).execute()
        
        print(f"Reporte insertado para sensor {sensor_id} de {start_time} a {now}")

# -----------------------------
# EJECUCIÓN
# -----------------------------
if __name__ == "__main__":
    run_etl()
