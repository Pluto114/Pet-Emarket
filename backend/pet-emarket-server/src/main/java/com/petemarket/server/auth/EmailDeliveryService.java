package com.petemarket.server.auth;

import com.petemarket.server.common.BusinessException;
import com.petemarket.server.config.PetEmarketProperties;
import java.nio.charset.StandardCharsets;
import java.util.Properties;
import org.springframework.http.HttpStatus;
import org.springframework.mail.MailException;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.stereotype.Service;

@Service
public class EmailDeliveryService {
    private final PetEmarketProperties properties;

    public EmailDeliveryService(PetEmarketProperties properties) {
        this.properties = properties;
    }

    public void sendRegisterCode(String email, String code, int expiresInSeconds) {
        PetEmarketProperties.Mail mail = properties.getMail();
        if (!mail.isEnabled()) {
            return;
        }
        if (isBlank(mail.getHost()) || isBlank(mail.getUsername()) || isBlank(mail.getPassword()) || isBlank(mail.getFrom())) {
            throw new BusinessException("100011", "SMTP mail is not configured", HttpStatus.SERVICE_UNAVAILABLE);
        }

        JavaMailSenderImpl sender = new JavaMailSenderImpl();
        sender.setHost(mail.getHost().trim());
        sender.setPort(mail.getPort());
        sender.setUsername(mail.getUsername().trim());
        sender.setPassword(mail.getPassword().trim());
        sender.setDefaultEncoding(StandardCharsets.UTF_8.name());

        Properties javaMail = sender.getJavaMailProperties();
        javaMail.put("mail.smtp.auth", "true");
        javaMail.put("mail.smtp.ssl.enable", Boolean.toString(mail.isSslEnabled()));
        javaMail.put("mail.smtp.starttls.enable", Boolean.toString(mail.isStarttlsEnabled()));
        javaMail.put("mail.smtp.connectiontimeout", "8000");
        javaMail.put("mail.smtp.timeout", "8000");
        javaMail.put("mail.smtp.writetimeout", "8000");

        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(mail.getFrom().trim());
        message.setTo(email);
        message.setSubject("Pet-Emarket 邮箱验证码");
        message.setText("""
                您正在注册 Pet-Emarket 账号。

                邮箱验证码：%s
                有效期：%d 分钟

                如果不是您本人操作，请忽略此邮件。
                """.formatted(code, Math.max(1, expiresInSeconds / 60)));

        try {
            sender.send(message);
        } catch (MailException exception) {
            throw new BusinessException("100012", "Failed to send email code", HttpStatus.BAD_GATEWAY);
        }
    }

    public boolean shouldExposeDevCode() {
        PetEmarketProperties.Mail mail = properties.getMail();
        return !mail.isEnabled() || mail.isDevCodeInResponse();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }
}
