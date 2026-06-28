package com.bionova.repository;

import com.bionova.entity.RoleBasedAccessControl;
import com.bionova.entity.RoleBasedAccessControlId;
import com.bionova.dto.RoleDto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RoleBasedAccessControlRepository extends JpaRepository<RoleBasedAccessControl, RoleBasedAccessControlId> {
    List<RoleBasedAccessControl> findByRoleId(Integer roleId);
    void deleteByRoleId(Integer roleId);

    @Query("SELECT DISTINCT new com.bionova.dto.RoleDto(r.roleId, r.roleNm) FROM RoleBasedAccessControl r")
    List<RoleDto> findDistinctRoles();

    @Query("SELECT COALESCE(MAX(r.roleId), 0) FROM RoleBasedAccessControl r")
    Integer findMaxRoleId();
}
