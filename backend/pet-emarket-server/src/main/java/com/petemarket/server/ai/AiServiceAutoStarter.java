package com.petemarket.server.ai;

import com.petemarket.server.config.PetEmarketProperties;
import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

@Component
public class AiServiceAutoStarter {
    private static final Logger log = LoggerFactory.getLogger(AiServiceAutoStarter.class);

    private final PetEmarketProperties properties;
    private final RestTemplateBuilder restTemplateBuilder;

    public AiServiceAutoStarter(PetEmarketProperties properties, RestTemplateBuilder restTemplateBuilder) {
        this.properties = properties;
        this.restTemplateBuilder = restTemplateBuilder;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void ensureLocalAiServiceStarted() {
        PetEmarketProperties.AiService config = properties.getAiService();
        if (!config.isEnabled() || !config.isAutoStart() || !isLocalhost(config.getBaseUrl())) {
            return;
        }
        if (isHealthy(config.getBaseUrl(), Duration.ofSeconds(6))) {
            log.info("AI service is already available at {}", config.getBaseUrl());
            return;
        }

        Path aiDir = findAiServiceDir();
        if (aiDir == null) {
            log.warn("AI service auto-start skipped: ai-recommendation-service directory was not found");
            return;
        }
        Path python = findPythonExecutable(aiDir);
        if (python == null) {
            log.info("AI service auto-start skipped: no Python found under {} (this is normal if AI runs separately)", aiDir);
            return;
        }

        try {
            startAiProcess(aiDir, python, config.getBaseUrl());
            waitForHealth(config.getBaseUrl(), config.getStartupTimeoutSeconds());
        } catch (IOException exception) {
            log.warn("AI service auto-start failed: {}", exception.getMessage());
        }
    }

    private boolean isHealthy(String baseUrl, Duration timeout) {
        try {
            RestTemplate restTemplate = restTemplateBuilder
                    .rootUri(baseUrl)
                    .setConnectTimeout(timeout)
                    .setReadTimeout(timeout)
                    .build();
            restTemplate.getForObject("/health", Object.class);
            return true;
        } catch (RestClientException exception) {
            return false;
        }
    }

    private void waitForHealth(String baseUrl, long timeoutSeconds) {
        long deadline = System.nanoTime() + Duration.ofSeconds(Math.max(1, timeoutSeconds)).toNanos();
        while (System.nanoTime() < deadline) {
            if (isHealthy(baseUrl, Duration.ofSeconds(6))) {
                log.info("AI service started at {}", baseUrl);
                return;
            }
            try {
                Thread.sleep(1000);
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
                return;
            }
        }
        log.warn("AI service process was started, but {} did not become healthy within {} seconds", baseUrl, timeoutSeconds);
    }

    private void startAiProcess(Path aiDir, Path python, String baseUrl) throws IOException {
        Path projectRoot = aiDir.getParent();
        File stdout = projectRoot.resolve("ai-service-live.log").toFile();
        File stderr = projectRoot.resolve("ai-service-error.log").toFile();
        String port = String.valueOf(aiPort(baseUrl));
        ProcessBuilder processBuilder = new ProcessBuilder(
                python.toAbsolutePath().toString(),
                "-m",
                "uvicorn",
                "app.main:app",
                "--host",
                "0.0.0.0",
                "--port",
                port)
                .directory(aiDir.toFile())
                .redirectOutput(ProcessBuilder.Redirect.appendTo(stdout))
                .redirectError(ProcessBuilder.Redirect.appendTo(stderr));
        loadEnv(projectRoot.resolve(".env"), processBuilder.environment());
        loadEnv(aiDir.resolve(".env"), processBuilder.environment());
        processBuilder.environment().putIfAbsent("PORT", port);
        processBuilder.start();
        log.info("AI service auto-start launched via {}", python);
    }

    private Path findAiServiceDir() {
        Path cwd = Path.of(System.getProperty("user.dir")).toAbsolutePath().normalize();
        Path[] candidates = new Path[] {
                cwd.resolve("ai-recommendation-service"),
                cwd.resolve("..").resolve("ai-recommendation-service"),
                cwd.resolve("..").resolve("..").resolve("ai-recommendation-service"),
                cwd.resolve("..").resolve("..").resolve("..").resolve("ai-recommendation-service"),
        };
        for (Path candidate : candidates) {
            Path normalized = candidate.normalize();
            if (Files.isDirectory(normalized)) {
                return normalized;
            }
        }
        return null;
    }

    private Path findPythonExecutable(Path aiDir) {
        Path[] candidates = new Path[] {
                aiDir.resolve(".venv-ai-win").resolve("Scripts").resolve("python.exe"),
                aiDir.resolve(".venv-ai").resolve("Scripts").resolve("python.exe"),
                aiDir.resolve(".venv-ai").resolve("bin").resolve("python.exe"),
                aiDir.resolve(".venv").resolve("Scripts").resolve("python.exe"),
                aiDir.resolve("app").resolve(".venv").resolve("Scripts").resolve("python.exe"),
        };
        for (Path candidate : candidates) {
            if (Files.isRegularFile(candidate)) {
                return candidate.normalize();
            }
        }
        // 回退：尝试系统 PATH 中的 python
        for (String cmd : new String[]{"python", "python3"}) {
            try {
                String result = new java.util.Scanner(Runtime.getRuntime().exec(new String[]{cmd, "--version"}).getInputStream())
                        .useDelimiter("\\A").next();
                if (result != null && !result.isBlank()) {
                    return Path.of(cmd);
                }
            } catch (Exception ignored) {}
        }
        return null;
    }

    private void loadEnv(Path envPath, Map<String, String> environment) throws IOException {
        if (!Files.isRegularFile(envPath)) {
            return;
        }
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
            if (!key.isEmpty()) {
                environment.put(key, value);
            }
        }
    }

    private int aiPort(String baseUrl) {
        int port = URI.create(baseUrl).getPort();
        return port > 0 ? port : 8001;
    }

    private boolean isLocalhost(String baseUrl) {
        try {
            String host = URI.create(baseUrl).getHost();
            return "localhost".equalsIgnoreCase(host) || "127.0.0.1".equals(host);
        } catch (IllegalArgumentException exception) {
            return false;
        }
    }
}
