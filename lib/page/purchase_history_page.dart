import 'package:flutter/material.dart';
import 'package:bigchanllger/constants/theme.dart';
import 'package:bigchanllger/models/purchase_record.dart';
import 'package:bigchanllger/service/database_service.dart';

class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBackgroundColor : AppTheme.lightBackgroundColor,
      appBar: AppBar(
        title: Text('购买历史', style: AppTheme.getTitleStyle(isDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<PurchaseRecord>>(
        future: DatabaseService().getPurchaseRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                '暂无购买记录',
                style: AppTheme.getTitleStyle(isDark),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final record = snapshot.data![index];
              return _PurchaseRecordCard(record: record, isDark: isDark);
            },
          );
        },
      ),
    );
  }
}

class _PurchaseRecordCard extends StatelessWidget {
  final PurchaseRecord record;
  final bool isDark;

  const _PurchaseRecordCard({
    required this.record,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isDark ? AppTheme.darkCardColor : AppTheme.lightCardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.title,
                  style: AppTheme.getTitleStyle(isDark),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '已完成',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.createdAt,
                  style: AppTheme.getSubtitleStyle(isDark),
                ),
                Text(
                  '+ C ${record.amount}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (record.expireAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '${record.expireAt} 过期',
                style: AppTheme.getSubtitleStyle(isDark),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
