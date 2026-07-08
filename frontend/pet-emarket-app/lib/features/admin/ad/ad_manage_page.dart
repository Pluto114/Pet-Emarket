import 'package:flutter/material.dart';

class AdManagePage extends StatelessWidget {
  const AdManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.campaign_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        Text('广告管理', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text('此模块用于管理首页轮播图、促销横幅、弹窗广告等运营位', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
          child: const Text('待开发', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange)),
        ),
        const SizedBox(height: 32),
        _infoCard(Icons.swipe, '轮播图管理', '配置首页 Banner 图片、跳转链接、展示顺序'),
        const SizedBox(height: 8),
        _infoCard(Icons.auto_awesome, '促销横幅', '创建限时活动横幅，设置展示时段和目标用户'),
        const SizedBox(height: 8),
        _infoCard(Icons.notifications_active, '弹窗广告', '配置首页弹窗广告，支持图片/视频/优惠券形式'),
        const SizedBox(height: 8),
        _infoCard(Icons.analytics, '投放统计', '查看广告曝光量、点击率、转化数据'),
      ]),
    );
  }

  Widget _infoCard(IconData icon, String title, String desc) {
    return SizedBox(
      width: 420,
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFF7A8B3C)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ),
      ),
    );
  }
}
