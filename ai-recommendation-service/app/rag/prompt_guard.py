"""
Prompt Guard — 输入安全检测
负责：敏感词过滤、注入检测、问题分类、健康类判断
"""

import re
from dataclasses import dataclass, field

# ==================== 敏感词库 ====================

SENSITIVE_PATTERNS = [
    r"习近平", r"共产党", r"台独", r"藏独", r"疆独",
    r"法轮功", r"六四", r"天安门",
    r"\b(?:sex|porn|fuck)\b",
    r"色情", r"裸体", r"成人",
    r"杀人", r"自杀", r"炸弹", r"恐怖",
    r"贩毒", r"赌博",
]

SENSITIVE_RE = [re.compile(p, re.IGNORECASE) for p in SENSITIVE_PATTERNS]

# ==================== Prompt Injection 检测 ====================

INJECTION_PATTERNS = [
    r"忽略(以上|之前|所有|前面).*(指令|规则|限制)",
    r"ignore\s+(previous|above|all).*(instruction|rule|constraint)",
    r"system\s*:",
    r"<\|im_start\|>",
    r"<\|im_end\|>",
    r"你(现在|必须|只能).*角色",
    r"忘记.*设定",
    r"forget.*setting",
    r"DAN\s*mode",
    r"jailbreak",
    r"忽略.*安全",
    r"bypass.*filter",
]

INJECTION_RE = [re.compile(p, re.IGNORECASE) for p in INJECTION_PATTERNS]

# ==================== 健康关键词 ====================

HEALTH_KEYWORDS = [
    "生病", "病了", "症状", "呕吐", "拉稀", "腹泻", "不吃", "不喝",
    "发烧", "咳嗽", "打喷嚏", "皮肤病", "脱毛", "抽搐", "骨折",
    "中毒", "过敏", "疫苗反应", "手术", "用药", "吃药",
    "健康", "疾病", "医院", "兽医", "治疗",
]

# ==================== 业务型问题关键词 ====================

BUSINESS_KEYWORDS = [
    "订单", "退款", "发货", "物流", "快递", "支付", "付款",
    "会员", "等级", "积分", "优惠券", "地址", "收货",
    "退单", "售后", "投诉",
]


@dataclass
class GuardResult:
    """Prompt Guard 检测结果"""
    passed: bool = True
    reason: str = ""
    question_type: str = "knowledge"   # knowledge | business
    is_health: bool = False
    needs_disclaimer: bool = False
    sanitized_text: str = ""
    flags: list[str] = field(default_factory=list)


def guard(text: str) -> GuardResult:
    """对用户输入执行完整安全检测"""
    result = GuardResult()
    text = text.strip()

    # 1. 长度检查
    if len(text) == 0:
        result.passed = False
        result.reason = "问题不能为空"
        return result

    if len(text) > 500:
        result.passed = False
        result.reason = f"问题长度超过限制（当前 {len(text)} 字符，上限 500 字符）"
        return result

    # 2. 敏感词检查
    for pattern in SENSITIVE_RE:
        if pattern.search(text):
            result.passed = False
            result.reason = "问题包含不当内容，请重新输入"
            result.flags.append("sensitive_content")
            return result

    # 3. Prompt Injection 检查
    for pattern in INJECTION_RE:
        if pattern.search(text):
            result.passed = False
            result.reason = "检测到异常输入，请重新输入"
            result.flags.append("injection_attempt")
            return result

    # 4. 问题分类：业务型 vs 知识型
    for kw in BUSINESS_KEYWORDS:
        if kw in text:
            result.question_type = "business"
            result.flags.append("business_question")
            break

    # 5. 健康类问题检测
    for kw in HEALTH_KEYWORDS:
        if kw in text:
            result.is_health = True
            result.needs_disclaimer = True
            result.flags.append("health_question")
            break

    result.sanitized_text = text
    return result
