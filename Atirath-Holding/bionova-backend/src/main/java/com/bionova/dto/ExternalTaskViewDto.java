package com.bionova.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ExternalTaskViewDto {

    private Long taskId;
    private String taskCd;
    private String taskNm;
    private String taskDesc;
    private Long prjId;
    private String prjNm;
    private String prjCd;
    private Long mId;
    private String mlstnTtl;
    private String mlstnCd;
    private LocalDate stDt;
    private LocalDate endDt;
    private Integer noOfDays;
    private String priority;
    private String taskSts;
    private String subStatus;
    private String addlRem;
    private String noteTxt;

    private Long extEmpId;
    private String extEmpNm;
    private String extEmpEmail;
    private String companyNm;

    private LocalDateTime expiryDt;
    private Boolean isExpired;
    private String expiredReason;  // "TASK_CLOSED" | "DUE_DATE_PASSED" | "INACTIVE"
    private String expiredMessage;

    private List<ChecklistItemDto> checklists;
    private List<AttachmentItemDto> attachments;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ChecklistItemDto {
        private Integer chkId;
        private String chkCd;
        private String chkNm;
        private String chkDesc;
        private Boolean chkSts;
    }

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class AttachmentItemDto {
        private Integer fileId;
        private String fileNm;
        private String atPath;
        private String atType;
    }
}
