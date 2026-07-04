package com.bionova.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "role_based_access_control")
@IdClass(RoleBasedAccessControlId.class)
@Getter
@Setter
public class RoleBasedAccessControl {

    @Id
    @Column(name = "role_id")
    private Integer roleId;

    @Column(name = "role_nm", nullable = false, length = 100)
    private String roleNm;

    @Id
    @Column(name = "screen_id")
    private Integer screenId;

    @Column(name = "view_flg")
    private Boolean viewFlg = false;

    @Column(name = "edit_flg")
    private Boolean editFlg = false;

    @Column(name = "add_flg")
    private Boolean addFlg = false;

    @Column(name = "delete_flg")
    private Boolean deleteFlg = false;
}
