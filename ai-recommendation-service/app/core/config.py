"""
应用配置管理
管理 MongoDB、LLM API、服务端口等配置项
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    """全局配置单例"""

    # ========== 服务配置 ==========
    APP_NAME: str = "AI Recommendation Service"
    APP_VERSION: str = "0.1.0"
    DEBUG: bool = True
    PORT: int = int(os.getenv("PORT", "8001"))

    # ========== MongoDB 配置 ==========
    MONGODB_HOST: str = os.getenv("MONGODB_HOST", "localhost")
    MONGODB_PORT: int = int(os.getenv("MONGODB_PORT", "27017"))
    MONGODB_USER: str = os.getenv("MONGODB_USER", "admin")
    MONGODB_PASSWORD: str = os.getenv("MONGODB_PASSWORD", "")
    MONGODB_DB: str = os.getenv("MONGODB_DB", "pet_emarket")
    MONGODB_AUTH_SOURCE: str = os.getenv("MONGODB_AUTH_SOURCE", "admin")

    @property
    def mongodb_uri(self) -> str:
        return (
            f"mongodb://{self.MONGODB_USER}:{self.MONGODB_PASSWORD}"
            f"@{self.MONGODB_HOST}:{self.MONGODB_PORT}"
            f"/{self.MONGODB_DB}?authSource={self.MONGODB_AUTH_SOURCE}"
        )

    # ========== LLM 配置（阿里云百炼） ==========
    LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")
    LLM_BASE_URL: str = os.getenv(
        "LLM_BASE_URL",
        "https://dashscope.aliyuncs.com/compatible-mode/v1",
    )
    LLM_MODEL: str = os.getenv("LLM_MODEL", "qwen-plus")
    LLM_MODEL_FAST: str = os.getenv("LLM_MODEL_FAST", "qwen-turbo")

    # ========== 后端服务地址（用于业务型问答回调） ==========
    BACKEND_API_BASE: str = os.getenv("BACKEND_API_BASE", "http://localhost:8080")

    # ========== 推荐算法参数 ==========
    RECOMMEND_WEIGHTS: dict = {
        "item_cf": 0.35,
        "markov": 0.25,
        "member_level": 0.10,
        "store_distance": 0.15,
        "hot_item": 0.10,
        "stock_status": 0.05,
    }
    DEFAULT_RECOMMEND_LIMIT: int = 10
    ITEM_CF_TOP_K: int = 50
    ITEM_CF_SIMILARITY_THRESHOLD: float = 0.3
    MARKOV_SEQUENCE_WINDOW: int = 10


settings = Settings()
