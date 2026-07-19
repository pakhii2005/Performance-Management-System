package com.epms.controller;

import com.epms.dto.TalentMatrixResponse;
import com.epms.dto.TeamAverageResponse;
import com.epms.service.AnalyticsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/analytics")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    @GetMapping("/talent-matrix")
    public ResponseEntity<List<TalentMatrixResponse>> getTalentMatrix() {
        List<TalentMatrixResponse> talentMatrix = analyticsService.getTalentMatrix();
        return ResponseEntity.ok(talentMatrix);
    }

    @GetMapping("/team-average/{managerId}")
    public ResponseEntity<TeamAverageResponse> getTeamAverage(@PathVariable Long managerId) {
        TeamAverageResponse teamAverage = analyticsService.getTeamAverage(managerId);
        return ResponseEntity.ok(teamAverage);
    }
}
