package com.epms.dto;

import com.epms.entity.Role;
import lombok.*;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserResponse {

    private Long id;
    private String firstName;
    private String lastName;
    private String email;
    private Role role;
    private String department;
    private Long managerId;
    private String managerName;
    private Integer employeeCount;
    private LocalDateTime createdAt;
    private Boolean enabled;
    private Boolean passwordResetRequired;
}
