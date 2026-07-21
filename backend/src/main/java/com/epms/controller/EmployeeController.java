package com.epms.controller;

import com.epms.dto.UserResponse;
import com.epms.dto.EvaluationResponse;
import com.epms.service.EmployeeService;
import com.epms.dto.PerformanceRadarResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class EmployeeController {

    private final EmployeeService employeeService;

    @GetMapping("/{employeeId}/profile")
    @PreAuthorize("@securityService.canAccessEmployee(principal.username, #employeeId)")
    public ResponseEntity<UserResponse> getEmployeeProfile(@PathVariable Long employeeId) {
        UserResponse profile = employeeService.getEmployeeProfile(employeeId);
        return ResponseEntity.ok(profile);
    }

    @GetMapping("/{employeeId}/evaluations")
    @PreAuthorize("@securityService.canAccessEmployee(principal.username, #employeeId)")
    public ResponseEntity<List<EvaluationResponse>> getEmployeeEvaluations(@PathVariable Long employeeId) {
        List<EvaluationResponse> evaluations = employeeService.getEmployeeEvaluations(employeeId);
        return ResponseEntity.ok(evaluations);
    }

    @GetMapping("/{employeeId}/performance-radar")
    @PreAuthorize("@securityService.canAccessEmployee(principal.username, #employeeId)")
    public ResponseEntity<List<PerformanceRadarResponse>> getEmployeePerformanceRadar(@PathVariable Long employeeId) {
        List<PerformanceRadarResponse> radarData = employeeService.getEmployeePerformanceRadar(employeeId);
        return ResponseEntity.ok(radarData);
    }
}
