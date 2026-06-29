package com.petemarket.server.ai;

import java.util.List;
import java.util.Locale;
import org.springframework.stereotype.Service;

@Service
public class AiAssistantService {
    private static final String HEALTH_NOTICE = "仅供参考，严重健康问题请咨询执业兽医。";
    private final AiGatewayClient aiGatewayClient;

    public AiAssistantService(AiGatewayClient aiGatewayClient) {
        this.aiGatewayClient = aiGatewayClient;
    }

    public AiChatResponse chat(AiChatRequest request) {
        return aiGatewayClient.chat(request).orElseGet(() -> localChat(request));
    }

    private AiChatResponse localChat(AiChatRequest request) {
        String question = request.question().trim();
        String normalized = question.toLowerCase(Locale.ROOT);

        if (containsAny(normalized, "拉稀", "腹泻", "呕吐", "疫苗", "驱虫", "发烧", "不吃", "diarrhea", "vaccine")) {
            return new AiChatResponse(
                    "可以先观察精神状态、饮水、排便频次和是否伴随呕吐。幼宠或症状超过 24 小时建议尽快就医；不要自行喂人用药。"
                            + HEALTH_NOTICE,
                    List.of("宠物健康", "疫苗驱虫", "兽医安全提示"),
                    List.of("记录症状时间线", "查看商品页疫苗和检疫信息", "必要时联系附近门店或宠物医院"),
                    true
            );
        }

        if (containsAny(normalized, "订单", "退款", "退单", "发货", "收货", "售后", "物流", "refund", "order")) {
            return new AiChatResponse(
                    "订单会按待支付、待发货、待收货、待评价、完成流转。退款需要先提交原因，后台审核通过后进入退单成功；活体宠物建议在收货前确认健康档案和检疫证明。",
                    List.of("订单状态机", "售后规则", "活体宠物验收"),
                    List.of("打开订单详情", "查看状态日志", "需要售后时提交退款原因"),
                    false
            );
        }

        if (containsAny(normalized, "推荐", "猫粮", "狗粮", "商品", "适合", "recommend", "food")) {
            return new AiChatResponse(
                    "系统会结合历史订单、热门商品、附近门店距离和马尔可夫链行为预测生成推荐，并返回推荐分与推荐理由。新手可以优先看同品类高评分商品和库存充足的附近门店商品。",
                    List.of("混合推荐", "Item-CF", "Markov Chain"),
                    List.of("查看推荐页", "筛选附近门店", "对比商品推荐理由"),
                    false
            );
        }

        return new AiChatResponse(
                "你可以告诉我宠物品种、年龄、预算和想解决的问题。我可以辅助做商品选择、附近门店建议、订单售后说明和基础养宠知识问答。",
                List.of("智能客服", "养宠助手"),
                List.of("补充宠物年龄和品种", "查看附近门店", "浏览推荐商品"),
                false
        );
    }

    private boolean containsAny(String text, String... keywords) {
        for (String keyword : keywords) {
            if (text.contains(keyword)) {
                return true;
            }
        }
        return false;
    }
}
