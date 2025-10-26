import os
import random
import time
from argparse import ArgumentParser
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
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


def now_bogota() -> datetime:
    """Fecha/hora actual en la zona horaria de Bogotá (configurable por env).

    Prioriza la variable de entorno SIM_TIMEZONE o TZ si están definidas; por
    defecto usa 'America/Bogota'. Retorna un datetime consciente de zona.
    """
    tz_name = os.environ.get('SIM_TIMEZONE') or os.environ.get('TZ') or 'America/Bogota'
    try:
        tz = ZoneInfo(tz_name)
    except Exception:
        # Fallback seguro a UTC si la zona no existe en el entorno
        tz = timezone.utc
    return datetime.now(tz)


class SensorSimulator:
    """
    Genera datos con patrón de uso parecido a lavamanos/bebedero:
    - Eventos cortos e intermitentes (segundos), con caudal mayor durante el uso.
    - Caudal en reposo ~0.
    - Turbidez correlacionada con caudal, pH estable ~7, conductividad estable con pequeño ruido.
    Notas: caudal ('flowRate') aproximado en L/min.
    """

    def __init__(self, n_sensors: int, seed: Optional[int] = None,
                 open_prob_per_hour: float = 0.05,
                 dirty_prob_per_hour: float = 0.2,
                 turbidity_spike_prob: float = 0.01,
                 intensity: float = 1.0):
        self.n = max(1, int(n_sensors))
        self.rnd = random.Random(seed)

        # Parámetros de anomalías (frecuencia configurable)
        self.open_prob_per_hour = max(0.0, float(open_prob_per_hour))
        self.dirty_prob_per_hour = max(0.0, float(dirty_prob_per_hour))
        self.turbidity_spike_prob = max(0.0, min(1.0, float(turbidity_spike_prob)))
        # Intensidad global de desviaciones (magnitud)
        self.intensity = max(0.1, float(intensity))

        # Severidades/duraciones por defecto para anomalías
        self.OPEN_MIN_S = 300.0   # 5 min
        self.OPEN_MAX_S = 900.0   # 15 min
        self.OPEN_FLOW_MIN = 6.0  # L/min
        self.OPEN_FLOW_MAX = 10.0 # L/min

        self.DIRTY_MIN_S = 300.0   # 5 min
        self.DIRTY_MAX_S = 1200.0  # 20 min
        self.DIRTY_EXTRA_MIN = 1.0 # NTU
        self.DIRTY_EXTRA_MAX = 3.0 # NTU

        self.SPIKE_MIN = 2.0 # NTU
        self.SPIKE_MAX = 5.0 # NTU

        self.state = {}
        for i in range(1, self.n + 1):
            self.state[i] = {
                'active': False,
                'remaining_s': 0.0,
                'target_flow_lpm': 0.0,
                'type': None,  # 'sink' | 'fountain'
                'cond_base': self.rnd.uniform(180, 350),
                'use_rate_per_min': self.rnd.uniform(0.08, 0.2),  # 5-12 usos/h aprox
                # Anomalía de llave abierta
                'open_active': False,
                'open_remaining_s': 0.0,
                'open_flow_lpm': 0.0,
                # Periodo de agua sucia
                'dirty_active': False,
                'dirty_remaining_s': 0.0,
                'dirty_extra_ntu': 0.0,
            }

    def _maybe_start_event(self, s):
        # 50/50 lavamanos vs bebedero
        if self.rnd.random() < 0.5:
            s['type'] = 'sink'
            s['remaining_s'] = self.rnd.uniform(10, 30)
            s['target_flow_lpm'] = self.rnd.uniform(4.0, 8.0)
        else:
            s['type'] = 'fountain'
            s['remaining_s'] = self.rnd.uniform(5, 15)
            s['target_flow_lpm'] = self.rnd.uniform(1.0, 3.0)
        s['active'] = True

    def sample(self, sensor_id: int, timestamp: datetime, dt_seconds: float):
        s = self.state[sensor_id]

        # --- Actualizar/arrancar anomalía de llave abierta ---
        if not s['open_active']:
            p_open = min(0.95, self.open_prob_per_hour * (dt_seconds / 3600.0))
            if self.rnd.random() < p_open:
                s['open_active'] = True
                s['open_remaining_s'] = self.rnd.uniform(self.OPEN_MIN_S, self.OPEN_MAX_S)
                base_flow = self.rnd.uniform(self.OPEN_FLOW_MIN, self.OPEN_FLOW_MAX)
                s['open_flow_lpm'] = max(0.0, base_flow * self.intensity)
        else:
            s['open_remaining_s'] -= dt_seconds
            if s['open_remaining_s'] <= 0:
                s['open_active'] = False
                s['open_flow_lpm'] = 0.0

        # --- Actualizar/arrancar periodo de agua sucia ---
        if not s['dirty_active']:
            p_dirty = min(0.95, self.dirty_prob_per_hour * (dt_seconds / 3600.0))
            if self.rnd.random() < p_dirty:
                s['dirty_active'] = True
                s['dirty_remaining_s'] = self.rnd.uniform(self.DIRTY_MIN_S, self.DIRTY_MAX_S)
                s['dirty_extra_ntu'] = self.rnd.uniform(self.DIRTY_EXTRA_MIN, self.DIRTY_EXTRA_MAX)
        else:
            s['dirty_remaining_s'] -= dt_seconds
            if s['dirty_remaining_s'] <= 0:
                s['dirty_active'] = False
                s['dirty_extra_ntu'] = 0.0

        # --- Eventos normales de uso (solo si NO hay llave abierta) ---
        if not s['open_active']:
            if not s['active']:
                p = min(0.95, s['use_rate_per_min'] * dt_seconds / 60.0)
                if self.rnd.random() < p:
                    self._maybe_start_event(s)
            else:
                s['remaining_s'] -= dt_seconds
                if s['remaining_s'] <= 0:
                    s['active'] = False
                    s['target_flow_lpm'] = 0.0
                    s['type'] = None

        # --- Caudal ---
        if s['open_active']:
            flow = max(0.0, self.rnd.normalvariate(s['open_flow_lpm'], s['open_flow_lpm'] * (0.06 * self.intensity)))
        elif s['active']:
            flow = max(0.0, self.rnd.normalvariate(s['target_flow_lpm'], s['target_flow_lpm'] * (0.10 * self.intensity)))
        else:
            # goteo minúsculo con leve efecto de intensidad (cap a 1.0 L/min)
            flow = max(0.0, self.rnd.uniform(0.0, min(0.2 * self.intensity, 1.0)))

        # --- Turbidez (NTU) correlacionada con caudal + ruido ligero ---
        turbidity = max(0.0, 0.3 + 0.12 * flow + self.rnd.uniform(-0.05, 0.15) * self.intensity)
        if s['dirty_active']:
            turbidity += s['dirty_extra_ntu'] * self.intensity
        if self.rnd.random() < self.turbidity_spike_prob:
            turbidity += self.rnd.uniform(self.SPIKE_MIN, self.SPIKE_MAX) * self.intensity  # pico configurable

        # --- pH: base cerca de 7, afecta agua sucia y pequeños desvíos ocasionales ---
        ph_val = 7.0 + self.rnd.uniform(-0.08, 0.08) * self.intensity
        if s['dirty_active']:
            # Agua más sucia tiende a bajar ligeramente el pH
            ph_val -= self.rnd.uniform(0.2, 0.5) * self.intensity
        # Pequeños desvíos esporádicos (ácido o básico)
        if self.rnd.random() < 0.005:
            ph_val += self.rnd.choice([-1, 1]) * self.rnd.uniform(0.15, 0.35) * self.intensity
        # Limitar a rango razonable
        ph = round(max(6.0, min(8.5, ph_val)), 2)

        # --- Conductividad estable alrededor de un valor base ---
        conductivity = round(s['cond_base'] + self.rnd.uniform(-8, 8) * self.intensity, 2)

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
                ts = now_bogota()
                r = sim.sample(sensor_id, ts, interval)
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
    # Frecuencias de eventos exagerados
    p.add_argument('--open-prob-per-hour', type=float, default=0.05,
                   help='Probabilidad por hora de evento "llave abierta" por sensor (0..1).')
    p.add_argument('--dirty-prob-per-hour', type=float, default=0.2,
                   help='Probabilidad por hora de periodo de "agua más sucia" por sensor (0..1).')
    p.add_argument('--turbidity-spike-prob', type=float, default=0.01,
                   help='Probabilidad por muestra de pico de turbidez (0..1).')
    # Intensidad global
    p.add_argument('--intensity', type=float, default=1.0,
                   help='Factor global de intensidad de desviaciones (magnitud: caudal, turbidez, pH, conductividad).')
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

    sim = SensorSimulator(
        args.sensors,
        seed=args.seed,
        open_prob_per_hour=args.open_prob_per_hour,
        dirty_prob_per_hour=args.dirty_prob_per_hour,
        turbidity_spike_prob=args.turbidity_spike_prob,
        intensity=args.intensity,
    )
    print(f"Simulando {sim.n} sensores, intervalo={args.interval}s, destino=InfluxDB bucket={influx_cfg['bucket']}")
    if duration is not None:
        print(f"Duración: {duration} segundos")

    run(sim, args.interval, duration, influx_cfg)


if __name__ == '__main__':
    main()
