package com.petemarket.server;

import com.petemarket.server.config.PetEmarketProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

@SpringBootApplication
@EnableConfigurationProperties(PetEmarketProperties.class)
public class PetEmarketServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(PetEmarketServerApplication.class, args);
    }
}
