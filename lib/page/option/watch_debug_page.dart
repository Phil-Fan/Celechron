import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:celechron/utils/utils.dart';
import 'package:celechron/page/flow/flow_controller.dart';
import 'package:celechron/model/period.dart';

class WatchDebugPage extends StatefulWidget {
  const WatchDebugPage({super.key});

  @override
  State<WatchDebugPage> createState() => _WatchDebugPageState();
}

class _WatchDebugPageState extends State<WatchDebugPage> {
  String _keychainStatus = '检查中...';
  String _userDefaultsStatus = '检查中...';
  String _appGroupStatus = '检查中...';
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    if (!Platform.isIOS) {
      setState(() {
        _keychainStatus = '仅支持 iOS';
        _userDefaultsStatus = '仅支持 iOS';
        _appGroupStatus = '仅支持 iOS';
      });
      return;
    }

    // 检查 Keychain
    final secureStorage = const FlutterSecureStorage();
    final synjonesAuth = await secureStorage.read(
      key: 'synjonesAuth',
      iOptions: secureStorageIOSOptions,
    );

    setState(() {
      if (synjonesAuth == null) {
        _keychainStatus = '❌ 未找到认证信息';
      } else {
        final preview = synjonesAuth.length > 10
            ? '${synjonesAuth.substring(0, 10)}...'
            : synjonesAuth;
        _keychainStatus = '✅ 已找到 (${synjonesAuth.length} 字符)\n预览: $preview';
      }
    });

    // 检查 UserDefaults - 直接读取 flowList，不创建 FlowController
    try {
      // 尝试获取已存在的 FlowController，如果不存在则直接读取 flowList
      RxList<Period>? flowList;
      try {
        final flowController = Get.find<FlowController>();
        flowList = flowController.flowList;
      } catch (_) {
        // FlowController 不存在，直接从 Get 读取 flowList
        try {
          flowList = Get.find<RxList<Period>>(tag: 'flowList');
        } catch (_) {
          // flowList 也不存在
          flowList = null;
        }
      }

      if (flowList == null || flowList.isEmpty) {
        setState(() {
          _userDefaultsStatus = '⚠️ 无日程数据\n(需要先有日程安排)';
        });
      } else {
        final flowCount = flowList.where((e) => e.type == PeriodType.flow).length;
        final totalCount = flowList.length;
        setState(() {
          _userDefaultsStatus = '✅ 有 $totalCount 条日程\n(其中 $flowCount 条 Flow 类型)';
        });
      }
    } catch (e) {
      setState(() {
        _userDefaultsStatus = '❌ 检查失败: $e';
      });
    }

    // 检查 App Group 配置
    setState(() {
      final groupId = kDebugMode
          ? 'group.top.celechron.celechron.debug'
          : 'group.top.celechron.celechron';
      _appGroupStatus = '✅ App Group: $groupId';
    });
  }

  Future<void> _syncToWatch() async {
    if (!Platform.isIOS) {
      _showMessage('仅支持 iOS');
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      // 尝试获取已存在的 FlowController
      FlowController flowController;
      try {
        flowController = Get.find<FlowController>();
      } catch (_) {
        // FlowController 不存在，这种情况不应该发生，但为了安全起见返回错误
        _showMessage('❌ FlowController 未初始化\n请先打开"接下来"页面');
        return;
      }
      
      flowController.refreshWidget();
      
      // 等待一下让同步完成
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 获取同步的数据统计
      try {
        final flowList = Get.find<RxList<Period>>(tag: 'flowList');
        final flowCount = flowList.where((e) => e.type == PeriodType.flow).length;
        final totalCount = flowList.length;
        _showMessage('✅ 同步成功\n\n已同步 $totalCount 条日程\n(其中 $flowCount 条 Flow 类型)\n\n请在 Watch 应用的"日程"页面查看日志输出');
      } catch (_) {
        _showMessage('✅ 同步成功\n\n请在 Watch 应用的"日程"页面查看日志输出');
      }
      _checkStatus();
    } catch (e) {
      _showMessage('❌ 同步失败: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('确定'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Watch 通信调试'),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Keychain 状态
                    _buildStatusCard(
                      'Keychain 状态',
                      _keychainStatus,
                      CupertinoIcons.lock,
                    ),
                    const SizedBox(height: 16),
                    
                    // UserDefaults 状态
                    _buildStatusCard(
                      'UserDefaults 状态',
                      _userDefaultsStatus,
                      CupertinoIcons.square_list,
                    ),
                    const SizedBox(height: 16),
                    
                    // App Group 状态
                    _buildStatusCard(
                      'App Group 配置',
                      _appGroupStatus,
                      CupertinoIcons.group,
                    ),
                    const SizedBox(height: 24),
                    
                    // 操作按钮
                    CupertinoButton.filled(
                      onPressed: _isSyncing ? null : _syncToWatch,
                      child: _isSyncing
                          ? const CupertinoActivityIndicator()
                          : const Text('手动同步到 Watch'),
                    ),
                    const SizedBox(height: 12),
                    CupertinoButton(
                      onPressed: _checkStatus,
                      child: const Text('刷新状态'),
                    ),
                    const SizedBox(height: 24),
                    
                    // 说明文字
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.secondarySystemGroupedBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '说明',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.label.resolveFrom(context),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Keychain: 存储认证信息，Watch 可直接读取\n'
                            '• UserDefaults: 存储日程数据，通过 App Group 共享\n'
                            '• 点击"手动同步"会将当前日程数据同步到 Watch',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.secondaryLabel.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String status, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: CupertinoColors.activeBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

