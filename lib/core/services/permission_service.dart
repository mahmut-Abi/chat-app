import 'package:permission_handler/permission_handler.dart' if (dart.library.html) 'dart:html' as ph;
import '../utils/platform_utils.dart';
import 'log_service.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  final _log = LogService();

  Future<Map<ph.Permission, ph.PermissionStatus>> checkAndRequestPermissions() async {
    if (kIsWeb || (!PlatformUtils.isIOS && !PlatformUtils.isAndroid)) {
      _log.info('非移动平台，跳过权限检查');
      return {};
    }

    _log.info('开始检查应用权限');

    // 根据平台定义需要的权限
    final permissions = _getRequiredPermissions();

    // 检查当前权限状态
    final statuses = await _checkPermissions(permissions);

    // 请求未授予的权限
    final deniedPermissions = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();

    if (deniedPermissions.isNotEmpty) {
      _log.info('需要请求的权限', {
        'permissions': deniedPermissions.map((p) => p.toString()).toList(),
      });
      return await _requestPermissions(deniedPermissions);
    }

    _log.info('所有权限已授予');
    return statuses;
  }

  // 获取需要的权限列表
  List<ph.Permission> _getRequiredPermissions() {
    if (PlatformUtils.isIOS) {
      return [
        // iOS 不需要网络权限（网络是默认的）
        // 但需要本地网络权限（iOS 14+）
        ph.Permission.photos, // 相册权限（可选）
        ph.Permission.camera, // 相机权限（可选）
        ph.Permission.notification, // 通知权限（可选）
      ];
    } else if (PlatformUtils.isAndroid) {
      return [
        ph.Permission.storage, // 存储权限
        ph.Permission.photos, // 相册权限
        ph.Permission.camera, // 相机权限
        ph.Permission.notification, // 通知权限
      ];
    }
    return [];
  }

  // 检查权限状态
  Future<Map<ph.Permission, ph.PermissionStatus>> _checkPermissions(
    List<ph.Permission> permissions,
  ) async {
    final statuses = <ph.Permission, ph.PermissionStatus>{};
    for (final permission in permissions) {
      try {
        statuses[permission] = await permission.status;
      } catch (e) {
        _log.warning('检查权限失败', {
          'permission': permission.toString(),
          'error': e.toString(),
        });
        statuses[permission] = ph.PermissionStatus.denied;
      }
    }
    return statuses;
  }

  // 请求权限
  Future<Map<ph.Permission, ph.PermissionStatus>> _requestPermissions(
    List<ph.Permission> permissions,
  ) async {
    _log.info('开始请求权限', {
      'permissions': permissions.map((p) => p.toString()).toList(),
    });

    try {
      final statuses = await permissions.request();

      // 记录权限请求结果
      for (final entry in statuses.entries) {
        _log.info('权限请求结果', {
          'permission': entry.key.toString(),
          'status': entry.value.toString(),
        });
      }

      return statuses;
    } catch (e) {
      _log.error('请求权限失败', {'error': e.toString()});
      return {};
    }
  }

  // 检查网络权限（仅 Android）
  Future<bool> checkNetworkPermission() async {
    if (PlatformUtils.isAndroid) {
      // Android 的网络权限是在 AndroidManifest.xml 中声明的
      // 不需要运行时请求
      return true;
    } else if (PlatformUtils.isIOS) {
      // iOS 的网络权限是默认的，不需要请求
      return true;
    }
    return true;
  }

  // 检查单个权限
  Future<bool> checkPermission(ph.Permission permission) async {
    try {
      final status = await permission.status;
      _log.debug('检查权限', {
        'permission': permission.toString(),
        'status': status.toString(),
      });
      return status.isGranted;
    } catch (e) {
      _log.error('检查权限失败', {
        'permission': permission.toString(),
        'error': e.toString(),
      });
      return false;
    }
  }

  // 请求单个权限
  Future<ph.PermissionStatus> requestPermission(ph.Permission permission) async {
    try {
      _log.info('请求权限', {'permission': permission.toString()});
      final status = await permission.request();
      _log.info('权限请求结果', {
        'permission': permission.toString(),
        'status': status.toString(),
      });
      return status;
    } catch (e) {
      _log.error('请求权限失败', {
        'permission': permission.toString(),
        'error': e.toString(),
      });
      return ph.PermissionStatus.denied;
    }
  }

  // 打开应用设置
  Future<bool> openSettings() async {
    _log.info('打开应用设置');
    return await ph.openAppSettings();
  }

  // 获取权限描述（用于UI显示）
  String getPermissionDescription(ph.Permission permission) {
    if (permission == ph.Permission.photos) {
      return '相册访问权限用于选择和分享图片';
    } else if (permission == ph.Permission.camera) {
      return '相机权限用于拍摄照片';
    } else if (permission == ph.Permission.notification) {
      return '通知权限用于接收重要消息提醒';
    } else if (permission == ph.Permission.storage) {
      return '存储权限用于保存和读取文件';
    }
    return '此权限用于应用正常运行';
  }

  // 获取权限名称
  String getPermissionName(ph.Permission permission) {
    if (permission == ph.Permission.photos) {
      return '相册';
    } else if (permission == ph.Permission.camera) {
      return '相机';
    } else if (permission == ph.Permission.notification) {
      return '通知';
    } else if (permission == ph.Permission.storage) {
      return '存储';
    }
    return permission.toString().split('.').last;
  }
}
