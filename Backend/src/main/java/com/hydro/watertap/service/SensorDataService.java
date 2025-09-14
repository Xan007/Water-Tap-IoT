package com.hydro.watertap.service;

import com.hydro.watertap.model.dto.SensorRawRecord;
import com.hydro.watertap.model.dto.SensorRecordDTO;
import com.influxdb.v3.client.InfluxDBClient;
import com.influxdb.v3.client.Point;
import com.influxdb.v3.client.PointValues;
import com.influxdb.v3.client.query.QueryOptions;
import com.influxdb.v3.client.query.QueryType;
import com.influxdb.v3.client.write.WriteOptions;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

@Service
public class SensorDataService {

    private final InfluxDBClient influxDBClient;

    public SensorDataService(InfluxDBClient influxDBClient) {
        this.influxDBClient = influxDBClient;
    }

    public List<SensorRecordDTO> getRecentSensorData(Integer minutes) {
        String sql = "SELECT * " +
                "FROM 'water_sensors' " +
                "WHERE time >= now() - interval '" + minutes + " minutes' " +
                "ORDER BY time ASC";

        return querySensorData(sql, Map.of());
    }

    public List<SensorRecordDTO> getHistoryRaw(Instant from, Instant to) {
        String sql = "SELECT * " +
                "FROM 'water_sensors' " +
                "WHERE time >= :from AND time <= :to " +
                "ORDER BY time ASC";

        Map<String, Object> params = Map.of(
                "from", from.toString(),
                "to", to.toString()
        );

        return querySensorData(sql, params);
    }

    private Duration pickChunkSize(Instant from, Instant to) {
        long days = Duration.between(from, to).toDays();

        if (days <= 7) return Duration.ofDays(1);
        if (days <= 30) return Duration.ofDays(5);
        if (days <= 90) return Duration.ofDays(10);
        if (days <= 180) return Duration.ofDays(15);
        return Duration.ofDays(30);
    }

    public List<SensorRecordDTO> getHistory(Instant from, Instant to) {
        Duration chunkSize = pickChunkSize(from, to);
        List<TimeRange> ranges = splitIntoChunks(from, to, chunkSize);

        return ranges.parallelStream()
                .map(r -> getHistoryRaw(r.start(), r.end()))
                .flatMap(List::stream)
                .toList();
    }


    private List<TimeRange> splitIntoChunks(Instant from, Instant to, Duration chunkSize) {
        List<TimeRange> chunks = new ArrayList<>();
        Instant currentStart = from;

        while (!currentStart.isAfter(to)) {
            Instant currentEnd = currentStart.plus(chunkSize);
            if (currentEnd.isAfter(to)) {
                currentEnd = to;
            }

            chunks.add(new TimeRange(currentStart, currentEnd));

            currentStart = currentEnd;
        }

        return chunks;
    }

    private record TimeRange(Instant start, Instant end) {}

    public void saveSensorData(List<SensorRecordDTO> records) {
        String database = "datos_agua";

        List<Point> points = new ArrayList<>();
        Instant stamp = Instant.now().minusSeconds(records.size());

        for (SensorRecordDTO record : records) {
            Point point = Point.measurement("water_sensors")
                    .setTag("sensor_id", String.valueOf(record.sensorId()))
                    .setFloatField("ph", record.ph() != null ? record.ph() : 0.0)
                    .setFloatField("turbidity", record.turbidity() != null ? record.turbidity() : 0.0)
                    .setFloatField("conductivity", record.conductivity() != null ? record.conductivity() : 0.0)
                    .setFloatField("flowRate", record.flowRate() != null ? record.flowRate() : 0.0)
                    .setTimestamp(record.timestamp() != null ? record.timestamp() : stamp);

            points.add(point);
        }

        influxDBClient.writePoints(points,
                new WriteOptions.Builder()
                        .database(database)
                        .build());
    }

    private Double getDouble(PointValues pv, String field, Double defaultValue) {
        Object val = pv.getField(field);
        if (val instanceof Number number) return number.doubleValue();
        return defaultValue;
    }

    private Instant getInstant(PointValues pv) {
        Number ts = pv.getTimestamp();
        if (ts == null) return Instant.now();
        long nanos = ts.longValue();
        return Instant.ofEpochSecond(nanos / 1_000_000_000L, nanos % 1_000_000_000L);
    }

    private List<SensorRecordDTO> querySensorData(String sql, Map<String, Object> params) {
        try (Stream<PointValues> results = influxDBClient.queryPoints(
                sql,
                params,
                new QueryOptions("datos_agua", QueryType.SQL)
        )) {
            return results
                    .parallel()
                    .map(pv -> SensorRecordDTO.fromRaw(
                            new SensorRawRecord(
                                    getInstant(pv),
                                    getTagAsInteger(pv, "sensor_id", null),
                                    Map.of(
                                            "ph", getDouble(pv, "ph", null),
                                            "turbidity", getDouble(pv, "turbidity", null),
                                            "conductivity", getDouble(pv, "conductivity", null),
                                            "flowRate", getDouble(pv, "flowRate", null)
                                    )
                            )
                    ))
                    .toList();
        }
    }

    private Integer getTagAsInteger(PointValues pv, String tagKey, Integer defaultValue) {
        Object val = pv.getTag(tagKey);
        if (val != null) {
            try {
                return Integer.valueOf(val.toString());
            } catch (NumberFormatException e) {
                return defaultValue;
            }
        }
        return defaultValue;
    }
}
