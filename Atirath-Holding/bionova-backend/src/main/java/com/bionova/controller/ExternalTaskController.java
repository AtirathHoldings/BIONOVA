package com.bionova.controller;

import com.bionova.dto.ExternalTaskUpdateDto;
import com.bionova.dto.ExternalTaskViewDto;
import com.bionova.service.ExternalTaskAccessService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.NoSuchElementException;

@RestController
@RequestMapping("/api/external-tasks")
public class ExternalTaskController {

    @Autowired
    private ExternalTaskAccessService externalTaskAccessService;

    /**
     * Public endpoint to fetch task details using the unique expiring magic link token.
     */
    @GetMapping("/{token}")
    public ResponseEntity<?> getTaskByToken(@PathVariable String token) {
        try {
            ExternalTaskViewDto dto = externalTaskAccessService.getTaskByToken(token);
            if (Boolean.TRUE.equals(dto.getIsExpired())) {
                return ResponseEntity.status(HttpStatus.GONE).body(Map.of(
                        "status", 410,
                        "error", "Link Expired",
                        "expiredReason", dto.getExpiredReason() != null ? dto.getExpiredReason() : "EXPIRED",
                        "message", dto.getExpiredMessage() != null ? dto.getExpiredMessage() : "This task access link has expired.",
                        "task", dto
                ));
            }
            return ResponseEntity.ok(dto);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "status", 404,
                    "error", "Not Found",
                    "message", e.getMessage()
            ));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of(
                    "status", 403,
                    "error", "Access Inactive",
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                    "status", 500,
                    "error", "Server Error",
                    "message", "An unexpected error occurred while retrieving task details"
            ));
        }
    }

    /**
     * Public endpoint for external employees to submit progress / update status on their assigned task.
     */
    @PutMapping("/{token}/update")
    public ResponseEntity<?> updateTaskStatus(@PathVariable String token, @RequestBody ExternalTaskUpdateDto updateDto) {
        try {
            ExternalTaskViewDto updated = externalTaskAccessService.updateTask(token, updateDto);
            return ResponseEntity.ok(updated);
        } catch (NoSuchElementException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", e.getMessage()));
        } catch (IllegalStateException e) {
            return ResponseEntity.status(HttpStatus.GONE).body(Map.of("message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", e.getMessage()));
        }
    }

    /**
     * Public endpoint for external employees to mark checklist items as done.
     */
    @RequestMapping(value = "/{token}/checklist/{chkId}", method = {RequestMethod.PUT, RequestMethod.PATCH, RequestMethod.POST})
    public ResponseEntity<?> updateChecklistItem(
            @PathVariable String token,
            @PathVariable Integer chkId,
            @RequestBody Map<String, Boolean> body) {
        try {
            Boolean chkSts = body.getOrDefault("chkSts", true);
            boolean success = externalTaskAccessService.updateChecklistItem(token, chkId, chkSts);
            return ResponseEntity.ok(Map.of("success", success, "chkId", chkId, "chkSts", chkSts));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", e.getMessage()));
        }
    }
}
