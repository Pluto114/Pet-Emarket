package com.petemarket.server;

import com.petemarket.server.config.PetEmarketProperties;
import java.io.IOException;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;
import java.util.Set;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(PetEmarketProperties.class)
public class PetEmarketServerApplication {
    public static void main(String[] args) {
        loadDotenv();
        SpringApplication.run(PetEmarketServerApplication.class, args);
    }

    private static void loadDotenv() {
        for (Path envPath : envCandidates()) {
            if (Files.isRegularFile(envPath)) {
                loadDotenvFile(envPath);
            }
        }
    }

    private static Set<Path> envCandidates() {
        Set<Path> candidates = new LinkedHashSet<>();
        addUpwardCandidates(candidates, Path.of(System.getProperty("user.dir")).toAbsolutePath().normalize());
        try {
            Path codePath = Path.of(PetEmarketServerApplication.class.getProtectionDomain()
                    .getCodeSource()
                    .getLocation()
                    .toURI()).toAbsolutePath().normalize();
            addUpwardCandidates(candidates, Files.isDirectory(codePath) ? codePath : codePath.getParent());
        } catch (URISyntaxException | NullPointerException ignored) {
            // Keep startup independent from how the app was packaged or launched.
        }
        return candidates;
    }

    private static void addUpwardCandidates(Set<Path> candidates, Path start) {
        Path cursor = start;
        for (int depth = 0; cursor != null && depth < 8; depth++) {
            candidates.add(cursor.resolve(".env"));
            candidates.add(cursor.resolve("Pet-Emarket").resolve(".env"));
            cursor = cursor.getParent();
        }
    }

    private static void loadDotenvFile(Path envPath) {
        try {
            for (String line : Files.readAllLines(envPath, StandardCharsets.UTF_8)) {
                String trimmed = line.trim();
                if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                    continue;
                }
                int equals = trimmed.indexOf('=');
                if (equals <= 0) {
                    continue;
                }
                String key = trimmed.substring(0, equals).trim();
                String value = trimmed.substring(equals + 1).trim();
                if (!key.isEmpty() && !value.isEmpty() && System.getProperty(key) == null && System.getenv(key) == null) {
                    System.setProperty(key, unquote(value));
                }
            }
        } catch (IOException ignored) {
            // If .env cannot be read, Spring will fall back to normal environment/config values.
        }
    }

    private static String unquote(String value) {
        if (value.length() >= 2
                && ((value.startsWith("\"") && value.endsWith("\""))
                || (value.startsWith("'") && value.endsWith("'")))) {
            return value.substring(1, value.length() - 1);
        }
        return value;
    }
}
