package com.epms.controller;

import com.epms.dto.ManagerMetricsResponse;
import com.epms.dto.TeamEmployeeResponse;
import com.epms.dto.EvaluationResponse;
import com.epms.service.ManagerService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/manager")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ManagerController {

    private final ManagerService managerService;

    @GetMapping("/{managerId}/employees")
    public ResponseEntity<List<TeamEmployeeResponse>> getTeamEmployees(@PathVariable Long managerId) {
        List<TeamEmployeeResponse> team = managerService.getTeamEmployees(managerId);
        return ResponseEntity.ok(team);
    }

    @GetMapping("/{managerId}/evaluations")
    public ResponseEntity<List<EvaluationResponse>> getSubmittedEvaluations(@PathVariable Long managerId) {
        List<EvaluationResponse> evaluations = managerService.getSubmittedEvaluations(managerId);
        return ResponseEntity.ok(evaluations);
    }

    @GetMapping("/{managerId}/metrics")
    public ResponseEntity<ManagerMetricsResponse> getMetrics(@PathVariable Long managerId) {
        ManagerMetricsResponse metrics = managerService.getMetrics(managerId);
        return ResponseEntity.ok(metrics);
    }
}
