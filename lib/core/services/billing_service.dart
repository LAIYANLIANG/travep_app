import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsufficientPointsException implements Exception {
  final String message;
  InsufficientPointsException(this.message);
}

class BillingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 取得目前帳號是否開啟計費機制
  Future<bool> isBillingEnabled() async {
    try {
      final doc = await _firestore.collection('config').doc('billing').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!['is_billing_enabled'] ?? false;
      }
    } catch (e) {
      // 讀取設定失敗時預設不計費，以防系統癱瘓
    }
    return false;
  }

  /// 檢查並扣點。如果點數足夠則扣點並回傳 true。
  /// 如果點數不足則拋出 InsufficientPointsException
  Future<bool> checkAndDeductPoints(int requiredPoints, {String collectionPrefix = 'travel_users'}) async {
    final enabled = await isBillingEnabled();
    if (!enabled) return true; // 全站關閉計費時直接放行

    final user = _auth.currentUser;
    if (user == null) {
      throw InsufficientPointsException('請先登入');
    }

    final userRef = _firestore.collection(collectionPrefix).doc(user.uid);

    return await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        throw InsufficientPointsException('找不到帳戶資料');
      }

      int freeQuota = snapshot.data()?['free_quota'] ?? 0;
      int points = snapshot.data()?['points'] ?? 0;

      // 優先扣除免費額度 (無論 requiredPoints 多少，扣 1 次額度抵銷該次服務)
      if (freeQuota > 0) {
        transaction.update(userRef, {'free_quota': freeQuota - 1});
        return true;
      }

      // 免費額度不足，改扣綠界點數
      if (points >= requiredPoints) {
        transaction.update(userRef, {'points': points - requiredPoints});
        return true;
      }

      // 點數不足以支付
      throw InsufficientPointsException('點數不足，請觀看廣告或前往儲值。');
    });
  }

  /// 看廣告獎勵：將 free_quota 補滿到 3
  Future<void> rewardAdsWatched({String collectionPrefix = 'travel_users'}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection(collectionPrefix).doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      int currentWatched = snapshot.data()?['ads_watched'] ?? 0;
      // 補滿 3 次免費額度，並累積廣告觀看次數
      transaction.update(userRef, {
        'free_quota': 3,
        'ads_watched': currentWatched + 1,
      });
    });
  }
}
