package com.bionova.entity.dispatchlogistics;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "transit_temperature_logs")
@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class TransitTemperatureLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sensor_tag", length = 50)
    private String sensorTag;

    @Column(name = "trip_number", length = 50)
    private String tripNumber;

    @Column(name = "cargo_type", length = 100)
    private String cargoType;

    @Column(name = "current_temp_c")
    private Double currentTempC;

    @Column(name = "min_threshold_c")
    private Double minThresholdC;

    @Column(name = "max_threshold_c")
    private Double maxThresholdC;

    @Column(name = "ambient_temp_c")
    private Double ambientTempC;

    @Column(name = "log_timestamp", length = 50)
    private String logTimestamp;

    @Column(name = "status", length = 50)
    private String status;
}
