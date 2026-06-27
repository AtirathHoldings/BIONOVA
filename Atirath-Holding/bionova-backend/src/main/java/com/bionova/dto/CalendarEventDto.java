package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CalendarEventDto {
    private String id;           // E.g., "TASK-1", "MILESTONE-5", "HOLIDAY-3", "MEETING-2"
    private String title;        // Display title of the event
    private String type;         // "TASK", "MILESTONE", "HOLIDAY", "MEETING"
    private LocalDate date;      // Event date
    private String time;         // Time string (e.g. "10:30 AM", "02:00 PM") or null
    private String status;       // Raw status (e.g., "WIP", "COMPLETED", "OPEN")
    private String code;         // E.g., "TSK-01", "MS-03"
    private String description;  // Additional remarks/notes
}
