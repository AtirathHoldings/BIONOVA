package com.bionova.config;

import com.bionova.entity.*;
import com.bionova.service.ActivityLogService;
import jakarta.persistence.PostPersist;
import jakarta.persistence.PostRemove;
import jakarta.persistence.PostUpdate;
import java.lang.reflect.Method;

public class AuditListener {

    @PostPersist
    public void onPostPersist(Object entity) {
        if (entity instanceof AttachmentMaster) {
            logAction(entity, "N/A", "UPLOADED");
        } else {
            logAction(entity, "N/A", "CREATED");
        }
    }

    @PostUpdate
    public void onPostUpdate(Object entity) {
        String status = getStatusValue(entity);
        logAction(entity, "UPDATED", status != null ? status : "MODIFIED");
    }

    @PostRemove
    public void onPostRemove(Object entity) {
        logAction(entity, "N/A", "DELETED");
    }

    private void logAction(Object entity, String actionFrom, String actionTo) {
        ActivityLogService logService = SpringContext.getBean(ActivityLogService.class);
        if (logService == null) {
            return;
        }

        try {
            String entityTyp = getEntityType(entity);
            Long entityId = getEntityId(entity);
            if (entityTyp != null && entityId != null) {
                logService.logActivity(entityTyp, entityId, actionFrom, actionTo);
            }
        } catch (Exception e) {
            // Silently catch exceptions to prevent disrupting main transactions
        }
    }

    private String getEntityType(Object entity) {
        if (entity instanceof ProjectLive) return "PROJECT";
        if (entity instanceof MilestoneLive) return "MILESTONE";
        if (entity instanceof TaskLive) return "TASK";
        if (entity instanceof ProjectDraft) return "PROJECT_DRAFT";
        if (entity instanceof MilestoneDraft) return "MILESTONE_DRAFT";
        if (entity instanceof TaskDraft) return "TASK_DRAFT";
        if (entity instanceof AttachmentMaster) return "DOCUMENT";
        return null;
    }

    private Long getEntityId(Object entity) {
        try {
            Method m = null;
            if (entity instanceof ProjectLive) m = entity.getClass().getMethod("getPrjId");
            else if (entity instanceof MilestoneLive) m = entity.getClass().getMethod("getMId");
            else if (entity instanceof TaskLive) m = entity.getClass().getMethod("getTaskId");
            else if (entity instanceof ProjectDraft) m = entity.getClass().getMethod("getDrftPrjId");
            else if (entity instanceof MilestoneDraft) m = entity.getClass().getMethod("getDrftMId");
            else if (entity instanceof TaskDraft) m = entity.getClass().getMethod("getDrftTaskId");
            else if (entity instanceof AttachmentMaster) {
                Method m2 = entity.getClass().getMethod("getFileId");
                Object val = m2.invoke(entity);
                if (val instanceof Integer) {
                    return ((Integer) val).longValue();
                }
                return (Long) val;
            }
            
            if (m != null) {
                Object val = m.invoke(entity);
                if (val instanceof Integer) {
                    return ((Integer) val).longValue();
                }
                return (Long) val;
            }
        } catch (Exception e) {
            // ignore
        }
        return null;
    }

    private String getStatusValue(Object entity) {
        try {
            Method m = null;
            if (entity instanceof ProjectLive) m = entity.getClass().getMethod("getPrjSts");
            else if (entity instanceof MilestoneLive) m = entity.getClass().getMethod("getMSts");
            else if (entity instanceof TaskLive) {
                Method m2 = entity.getClass().getMethod("getTaskSts");
                Object val = m2.invoke(entity);
                if (val != null) {
                    return val.toString();
                }
            }
            else if (entity instanceof ProjectDraft) m = entity.getClass().getMethod("getPrjSts");
            else if (entity instanceof MilestoneDraft) m = entity.getClass().getMethod("getMSts");
            else if (entity instanceof TaskDraft) {
                Method m2 = entity.getClass().getMethod("getTaskSts");
                Object val = m2.invoke(entity);
                if (val != null) {
                    return val.toString();
                }
            }
            
            if (m != null) {
                Object val = m.invoke(entity);
                return val != null ? val.toString() : null;
            }
        } catch (Exception e) {
            // ignore
        }
        return null;
    }
}
