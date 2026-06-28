package com.bionova.entity;

import java.io.Serializable;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoleBasedAccessControlId implements Serializable {
    private Integer roleId;
    private Integer screenId;
}
