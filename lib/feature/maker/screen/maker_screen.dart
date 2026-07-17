import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/screen/scan_tab_screen.dart';
import 'package:flutter/material.dart';

class MakerScreen extends StatelessWidget {
  const MakerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: ColorConstants.border),
              ),
            ),
            child: TabBar(
              labelStyle: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTextStyles.body,
              labelColor: ColorConstants.primaryColor,
              unselectedLabelColor: ColorConstants.textSecondary,
              indicatorColor: ColorConstants.primaryColor,
              indicatorWeight: 2,
              tabs: const [
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.document_scanner_rounded, size: 17),
                      SizedBox(width: 7),
                      Text('Auto Scan'),
                    ],
                  ),
                ),
                Tab(
                  height: 42,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_document, size: 17),
                      SizedBox(width: 7),
                      Text('Manual Scan'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ScanTabScreen(isAuto: true),
                ScanTabScreen(isAuto: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
