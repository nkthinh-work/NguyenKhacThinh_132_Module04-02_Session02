package com.quickbite.userservice;

import java.util.Map;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/users")
public class DatabaseController {
    private final JdbcTemplate jdbcTemplate;

    public DatabaseController(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @GetMapping("/db-info")
    public Map<String, Object> info() {
        // A successful JDBC query proves the host/container can reach PostgreSQL.
        return jdbcTemplate.queryForMap(
            "SELECT current_database() AS database, current_user AS username, " +
            "current_setting('server_version') AS postgresql_version"
        );
    }
}
