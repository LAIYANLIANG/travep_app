import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/billing_service.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  Future<void> _handleTopUp(BuildContext context, int amount, int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }

    // 綠界 Server-to-Server 串接 API 呼叫 (模擬)
    // 預計對接 python backend: POST http://localhost:8080/api/ecpay/create-order
    // 為求展示順暢，這裡使用 alert 告知
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('即將跳轉綠界金流'),
        content: Text('即將為您建立 NT\$$amount 的訂單以購買 $points 點。\n(此為展示階段，將不會真的扣款)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // 此行未來會改為真的開啟 ECPay URL
              final Uri url = Uri.parse('https://payment-stage.ecpay.com.tw/Cashier/AioCheckOut/V5');
              await launchUrl(url); 
            },
            child: const Text('確定前往'),
          )
        ],
      )
    );
  }

  Future<void> _handleWatchAd(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('正在播放模擬廣告...')));
    await Future.delayed(const Duration(seconds: 3));
    
    await BillingService().rewardAdsWatched();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('觀看完成！已補充 3 次免費額度。'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('請先登入以檢視點數'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('繳費與儲值管理'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('travel_users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final int points = data?['points'] ?? 0;
          final int freeQuota = data?['free_quota'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 狀態儀表板
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        title: '目前點數',
                        value: '$points 點',
                        icon: Icons.monetization_on,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        title: '剩餘免費額度',
                        value: '$freeQuota 次',
                        icon: Icons.card_giftcard,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 廣告解鎖區
                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_filled, size: 40, color: Colors.blueAccent),
                    title: const Text('看廣告換免費額度', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('觀看完 30 秒贊助商廣告，立即補充 3 次免費 AI 分析！'),
                    trailing: ElevatedButton(
                      onPressed: () => _handleWatchAd(context),
                      child: const Text('觀看'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 綠界儲值方案
                const Text('綠界儲值方案', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildTopUpPlan(context, price: 100, pointsStr: '100', desc: '純新手體驗包'),
                const SizedBox(height: 12),
                _buildTopUpPlan(context, price: 500, pointsStr: '550', desc: '+50 點獎勵（暢快規劃推薦）', isPopular: true),
                const SizedBox(height: 12),
                _buildTopUpPlan(context, price: 1000, pointsStr: '1200', desc: '+200 點獎勵（深度旅遊玩家）'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTopUpPlan(BuildContext context, {required int price, required String pointsStr, required String desc, bool isPopular = false}) {
    return Card(
      elevation: isPopular ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isPopular ? Colors.amber.shade700 : Colors.transparent, width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(Icons.account_balance_wallet, size: 40, color: isPopular ? Colors.amber.shade700 : Colors.grey),
        title: Text('NT\$ $price', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        subtitle: Text('獲得 $pointsStr 點\n$desc', style: const TextStyle(height: 1.5)),
        isThreeLine: true,
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPopular ? Colors.amber.shade700 : Colors.grey.shade800,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _handleTopUp(context, price, int.parse(pointsStr)),
          child: const Text('綠界付款'),
        ),
      ),
    );
  }
}
