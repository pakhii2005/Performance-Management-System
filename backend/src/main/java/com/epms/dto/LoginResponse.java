package com.epms.dto;

import com.epms.entity.Role;
import lombok.*;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class LoginResponse {

    private Long id;
    private String firstName;
    private String lastName;
    private String email;
    private Role role;
}
