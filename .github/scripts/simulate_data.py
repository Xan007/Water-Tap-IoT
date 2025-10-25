import os
import random
import time
from argparse import ArgumentParser
from datetime import datetime, timezone
from typing import Optional

from influxdb_client import InfluxDBClient, Point, WriteOptions


def parse_duration(s: Optional[str]) -> Optional[float]:
    if s is None:
        return None
    s = s.strip().lower()
    try:
        return float(s)
    except ValueError:
        pass
    if s.endswith('h'):
        return float(s[:-1]) * 3600
    if s.endswith('m'):
        return float(s[:-1]) * 60
    if s.endswith('s'):
        return float(s[:-1])
    raise ValueError(f"Duración inválida: {s}")


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


class SensorSimulator:
    def __init__(self, n_sensors: int, seed: Optional[int] = None):
        self.n = max(1, int(n_sensors))
        self.rnd = random.Random(seed)
        self.baselines = {}
        for i in range(1, self.n + 1):
            self.baselines[i] = {
                'flow': self.rnd.uniform(0.1, 5.0),
                'turbidity': self.rnd.uniform(0.1, 2.0),
                'ph': self.rnd.uniform(6.8, 7.5),
                'conductivity': self.rnd.uniform(150, 400),
            }

    def sample(self, sensor_id: int, timestamp: datetime):
        b = self.baselines[sensor_id]
        flow = max(0.0, b['flow'] + self.rnd.uniform(-0.5, 0.5))
        turbidity = max(0.0, b['turbidity'] + self.rnd.uniform(-0.2, 0.8))
        ph = round(b['ph'] + self.rnd.uniform(-0.1, 0.1), 2)
        conductivity = round(b['conductivity'] + self.rnd.uniform(-10, 10), 2)

        if self.rnd.random() < 0.01:
            turbidity += self.rnd.uniform(3, 8)
        if self.rnd.random() < 0.005:
            flow *= self.rnd.uniform(0.2, 4)

        return {
            'sensor_id': sensor_id,
            'timestamp': timestamp,
            'flowRate': round(flow, 3),
            'turbidity': round(turbidity, 3),
            'ph': ph,
            'conductivity': conductivity,
        }


def run(sim: SensorSimulator, interval: float, duration: Optional[float], influx_cfg: dict):
    if interval <= 0:
        raise ValueError("El intervalo debe ser > 0")
    if sim.n <= 0:
        raise ValueError("La cantidad de sensores debe ser >= 1")

    stagger = interval / sim.n  # para que no manden todos a la vez
    end_time = time.time() + duration if duration is not None else None

    client = InfluxDBClient(url=influx_cfg['url'], token=influx_cfg['token'], org=influx_cfg['org'])
    write_api = client.write_api(write_options=WriteOptions(batch_size=1))  # escribir punto a punto
    bucket = influx_cfg.get('bucket', 'datos_agua')

    start = time.time()
    sent = 0
    try:
        while True:
            for sensor_id in range(1, sim.n + 1):
                ts = now_utc()
                r = sim.sample(sensor_id, ts)
                p = Point("water_sensors").tag("sensor_id", str(r['sensor_id'])) \
                    .field("flowRate", float(r['flowRate'])) \
                    .field("turbidity", float(r['turbidity'])) \
                    .field("ph", float(r['ph'])) \
                    .field("conductivity", float(r['conductivity'])) \
                    .time(r['timestamp'])
                write_api.write(bucket=bucket, record=p)
                sent += 1
                time.sleep(stagger)

            if end_time is not None and time.time() >= end_time:
                break
    except KeyboardInterrupt:
        pass
    finally:
        try:
            write_api.__del__()
        except Exception:
            pass
        client.close()
        elapsed = time.time() - start
        print(f"Envío finalizado. Puntos enviados: {sent}. Tiempo: {elapsed:.1f}s")


def main(argv=None):
    p = ArgumentParser(description='Simulador simple en tiempo real hacia InfluxDB')
    p.add_argument('--sensors', '-n', type=int, default=4, help='Cantidad de sensores a simular')
    p.add_argument('--interval', '-i', type=float, default=5.0, help='Intervalo entre lecturas (segundos)')
    p.add_argument('--duration', '-d', type=str, default=None, help="Duración total: segundos o '1h','30m','45s'")
    p.add_argument('--seed', type=int, default=None, help='Semilla opcional para reproducibilidad')
    args = p.parse_args(argv)

    duration = parse_duration(args.duration)

    influx_cfg = {
        'url': os.environ.get('INFLUXDB_URL'),
        'token': os.environ.get('INFLUXDB_TOKEN'),
        'org': os.environ.get('INFLUXDB_ORG'),
        'bucket': os.environ.get('INFLUXDB_BUCKET', 'datos_agua'),
    }
    missing = [k for k, v in influx_cfg.items() if k in ('url', 'token', 'org') and not v]
    if missing:
        raise SystemExit(f"Faltan variables de entorno para InfluxDB: {', '.join(missing)}")

    sim = SensorSimulator(args.sensors, seed=args.seed)
    print(f"Simulando {sim.n} sensores, intervalo={args.interval}s, destino=InfluxDB bucket={influx_cfg['bucket']}")
    if duration is not None:
        print(f"Duración: {duration} segundos")

    run(sim, args.interval, duration, influx_cfg)


if __name__ == '__main__':
    main()
