package com.petemarket.server.payment;

import com.petemarket.server.order.PetOrder;
import com.petemarket.server.user.UserAccount;
import com.petemarket.server.user.UserRole;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PaymentService {
    private final PaymentRecordRepository paymentRecordRepository;

    public PaymentService(PaymentRecordRepository paymentRecordRepository) {
        this.paymentRecordRepository = paymentRecordRepository;
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> list(UserAccount currentUser) {
        List<PaymentRecord> records = isAdminOrMerchant(currentUser)
                ? paymentRecordRepository.findAllByOrderByCreatedAtDesc()
                : paymentRecordRepository.findByUserIdOrderByCreatedAtDesc(currentUser.getId());
        return records.stream().map(PaymentResponse::from).toList();
    }

    public PaymentRecord recordPayment(PetOrder order) {
        return paymentRecordRepository.findByOrderIdAndType(order.getId(), PaymentType.PAY)
                .orElseGet(() -> save(order, PaymentType.PAY, "Demo balance payment"));
    }

    public PaymentRecord recordRefund(PetOrder order, String reason) {
        return paymentRecordRepository.findByOrderIdAndType(order.getId(), PaymentType.REFUND)
                .orElseGet(() -> save(order, PaymentType.REFUND, reason));
    }

    private PaymentRecord save(PetOrder order, PaymentType type, String remark) {
        PaymentRecord record = new PaymentRecord();
        record.setPaymentNo(type.name() + Instant.now().toEpochMilli() + order.getId());
        record.setOrderId(order.getId());
        record.setOrderNo(order.getOrderNo());
        record.setUserId(order.getUserId());
        record.setType(type);
        record.setAmount(order.getPayAmount());
        record.setRemark(remark);
        record.setPaidAt(Instant.now());
        return paymentRecordRepository.save(record);
    }

    private boolean isAdminOrMerchant(UserAccount user) {
        return user.getRole() == UserRole.ADMIN || user.getRole() == UserRole.MERCHANT;
    }
}
