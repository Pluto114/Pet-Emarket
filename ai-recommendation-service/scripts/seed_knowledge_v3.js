// Pet-Emarket 知识库种子 v3 2026-07-03
// 条数: 23

use pet_emarket;
db.knowledge_base.deleteMany({});

db.knowledge_base.insertMany([
  {title:"宠物品种选择",category:"selecting_pet",source:"宠物百科",createTime:new Date(),content:"德牧犬品种特点：德国牧羊犬原产德国是世界上最聪明犬种之一。身体结构均衡强壮工作能力极强。性格忠诚勇敢警惕自信对主人无比忠诚。需要大量运动和训练不适合没有时间的主人。是优秀的警犬搜救犬和导盲犬。健康方面需关注髋关节发育不良和胃扩张扭转风险。"},
  {title:"宠物品种选择",category:"selecting_pet",source:"宠物百科",createTime:new Date(),content:"柯基犬品种特点：彭布罗克威尔士柯基犬是小型牧牛犬体重十一到十四公斤。标志性的大耳朵圆屁股和短腿让它成为网红犬种。性格聪明活泼勇敢但有时固执。运动需求中等每天散步加玩耍即可。因体型特殊不能过度爬楼梯防脊椎损伤。"},
  {title:"宠物品种选择",category:"selecting_pet",source:"宠物百科",createTime:new Date(),content:"哈士奇品种特点：西伯利亚哈士奇原产俄罗斯极寒地区以拉雪橇闻名。体重十六到二十五公斤。标志性的蓝眼睛或异色眼厚实双层被毛。性格友善开朗固执独立。精力极其旺盛需要每天大量的运动。极其擅长越狱和拆家需要牢固的围栏和充足的体力和精神消耗。"},
  {title:"宠物品种选择",category:"selecting_pet",source:"宠物百科",createTime:new Date(),content:"波斯猫品种特点：波斯猫是世界上最古老和最被认可的纯种猫之一。圆圆的脸短短扁扁的鼻子长而华丽的被毛。性格安静温和高贵不急不躁适合安静的家庭。美容需求极高需要每天梳理防止打结和每天用湿布清洁面部皱褶和眼部分泌物。"},
  {title:"犬猫营养基础",category:"feeding",source:"MSD兽医手册",createTime:new Date(),content:"宠物食品中常添加的功能性成分：益生菌可促进肠道健康调节免疫功能；益生元如果寡糖为有益菌提供食物选择性促进益生菌繁殖；Omega-3脂肪酸来源包括鱼油和亚麻籽油有助于皮肤健康和抗炎；葡萄糖胺和硫酸软骨素常用于关节保健配方中支持软骨健康和关节润滑。"},
  {title:"犬猫营养基础",category:"feeding",source:"MSD兽医手册",createTime:new Date(),content:"帮助宠物减肥的饮食策略：使用专门的低热量高纤维配方粮。严格控制每日食物总量使用厨房秤精确称量。减少或停止喂零食。将一天的食品分成多次小量喂食延长饱腹感。使用慢食碗或益智喂食器延长进食时间。"},
  {title:"犬猫营养基础",category:"feeding",source:"MSD兽医手册",createTime:new Date(),content:"犬猫营养中的牛磺酸问题：牛磺酸是猫的必需氨基酸而犬可以自身合成。猫缺乏牛磺酸会导致扩张型心肌病中心性视网膜变性和生殖障碍。这也是猫绝对不能长期吃狗粮的核心原因。所有猫粮必须额外添加牛磺酸。早期牛磺酸缺乏症通过补充牛磺酸是可逆的。"},
  {title:"犬猫营养基础",category:"feeding",source:"MSD兽医手册",createTime:new Date(),content:"AAFCO是美国饲料管理协会的缩写。AAFCO不直接测试或认证宠物食品而是制定犬猫食品的营养标准。AAFCO声明表示该食品要么通过配方计算要么通过喂养试验满足了特定生命阶段的营养需求。只有带有AAFCO声明的商业宠粮才能作为犬猫的唯一食物来源。"},
  {title:"宠物美容护理",category:"daily_care",source:"宠物百科",createTime:new Date(),content:"不同被毛类型犬的梳理需求：短毛犬使用橡胶刷或鬃毛刷每周一到二次去除死毛、中毛犬如金毛使用排梳加针梳每周二到三次、长毛犬每天梳理以防打结和毡化、梗犬类刚毛被毛需要定期拔毛以保持被毛的硬质和质感。"},
  {title:"宠物美容护理",category:"daily_care",source:"宠物百科",createTime:new Date(),content:"犬猫肛门腺护理：犬猫肛门两侧各有一个小囊状结构分泌特殊气味物质用于标记领地和个体识别。如果肛门腺堵塞或感染宠物会出现在地上拖屁股行走频繁舔舐肛门周围尾巴夹紧。兽医或美容师可手动挤压排空肛门腺。反复发作可能需要冲洗甚至手术摘除。"},
  {title:"宠物美容护理",category:"daily_care",source:"宠物百科",createTime:new Date(),content:"猫咪毛球问题的管理：猫咪在梳理被毛时会吞入死毛大部分通过消化道从粪便排出。过多的死毛在胃内聚集成团形成毛球猫会通过呕吐排出。经常呕吐毛球的猫需要增加梳理频率减少死毛摄入。使用毛球控制配方的猫粮和化毛膏帮助毛球安全通过消化道。"},
  {title:"犬常见外科",category:"dog_health",source:"MSD兽医手册",createTime:new Date(),content:"犬十字韧带断裂是犬最常见的骨科急诊之一。十字韧带是膝关节内最关键的稳定结构。急性断裂通常在运动中突然发生犬会立即三条腿行走受伤腿无法着地。慢性退行性断裂更多见犬表现为渐进性跛行尤其运动后加重坐下时受伤腿不敢弯曲向外侧伸直。"},
  {title:"犬常见外科",category:"dog_health",source:"MSD兽医手册",createTime:new Date(),content:"犬髌骨脱位常见于玩具犬和小型犬包括泰迪吉娃娃博美约克夏等。髌骨从股骨滑车沟中脱出往往是内侧脱出。犬表现为突然跳跃步态后肢踢甩一下随即恢复正常。严重脱位需要手术矫正包括加深滑车沟和胫骨粗隆移位术。"},
  {title:"犬常见外科",category:"dog_health",source:"MSD兽医手册",createTime:new Date(),content:"犬耳血肿通常在过度甩头或抓耳后发生耳廓内小血管破裂血液在耳廓软骨和皮肤之间积聚使耳廓肿胀像小枕头。最常继发于耳部感染和过敏。治疗需要全麻下手术切开排出血凝块并缝合固定耳廓防止复发。"},
  {title:"猫咪传染病",category:"cat_health",source:"MSD兽医手册",createTime:new Date(),content:"猫泛白细胞减少症猫瘟是一种高度传染性常致命的病毒性疾病。该病毒细小病毒在全球广泛存在可在环境中存活超过一年需要强力消毒剂才能灭活。幼猫最易感。潜伏期二到七天后出现发热精神萎靡食欲不振恶心。一到二天后出现呕吐和严重脱水。"},
  {title:"猫咪传染病",category:"cat_health",source:"MSD兽医手册",createTime:new Date(),content:"猫传染性腹膜炎是由猫冠状病毒突变引起的严重致死性疾病。最常见于幼猫和多猫环境中的猫。分为湿性和干性两种类型。湿性特征性体腔积液包括腹水和胸腔积液导致腹部膨大和呼吸困难。干性形成各器官肉芽肿性炎症灶。"},
  {title:"猫咪传染病",category:"cat_health",source:"MSD兽医手册",createTime:new Date(),content:"猫疱疹病毒感染的长期管理：猫感染猫疱疹病毒后会终身带毒。在应激情况如搬家新增家庭成员或宠物时可复发出现打喷嚏眼鼻分泌物等症状。长期管理策略包括减少环境应激使用面部费洛蒙扩散剂创造安全感在兽医指导下补充赖氨酸。"},
  {title:"宠物居家安全",category:"environment",source:"宠物百科",createTime:new Date(),content:"对犬有毒的庭院植物：夹竹桃所有部分都有剧毒可致心律失常致死；杜鹃花含灰毒素摄入后几小时出现呕吐流涎腹泻心律失常和低血压；蓖麻籽含蓖麻毒蛋白引起严重消化道症状和器官衰竭；苏铁所有部分都有毒尤其种子毒性最强可致急性肝衰竭。"},
  {title:"宠物居家安全",category:"environment",source:"宠物百科",createTime:new Date(),content:"对猫有剧毒的植物：所有品种的百合花成员所有部位都剧毒即使极少量的花粉花瓣叶子甚至花瓶水。摄入后十二到三十六小时出现呕吐嗜睡继而进入急性肾衰竭期。如果猫吃了百合花必须立即急诊催吐加四十八小时静脉利尿输液。"},
  {title:"疫苗免疫",category:"vaccination",source:"MSD兽医手册",createTime:new Date(),content:"犬窝咳犬传染性气管支气管炎是多病原体引发的急性高传染性呼吸道疾病。最常见病原体为支气管败血波氏杆菌和犬副流感病毒。症状包括特征性的干咳声音如鹅叫或卡喉咙有时伴随呕出白色泡沫样痰。多数犬精神食欲正常仅表现为持续一到三周的干咳。高风险犬建议接种窝咳疫苗。"},
  {title:"疫苗免疫",category:"vaccination",source:"MSD兽医手册",createTime:new Date(),content:"宠物不需要每年打全所有疫苗。现代兽医以个体化风险评估为基础制定疫苗方案称为风险分层疫苗接种。核心疫苗提供数年稳固保护力如犬DHPP和猫FVRCP每三年强化即可而非核心疫苗如钩端螺旋体每年接种因为其免疫持续期短。"},
  {title:"宠物急救处理",category:"health_general",source:"MSD兽医手册",createTime:new Date(),content:"犬猫心肺复苏CPR基本步骤：首先检查意识呼吸和心跳。无意识且无呼吸需要立即CPR。犬猫摆右侧卧位心脏朝上。小型犬猫用单手或双手在第四到第六肋间按压胸廓按压深度为胸廓宽度三分之一到二分之一。频率每分钟一百到一百二十次。每十五次按压配合二次人工呼吸。"},
  {title:"宠物急救处理",category:"health_general",source:"MSD兽医手册",createTime:new Date(),content:"宠物呛噎的处理：如果宠物用力咳嗽能呼吸能发声说明气道不完全阻塞不要盲目用手掏取。鼓励咳嗽排出异物。如果宠物不能呼吸发绀或失去意识需要立即急救。大型犬站在其背后双手握拳置于腹部最后一对肋骨下方快速向上向内挤压。"}
]);

print("v3: " + db.knowledge_base.countDocuments() + " docs");
