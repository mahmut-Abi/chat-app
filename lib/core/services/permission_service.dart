import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
 import '../utils/platform_utils.dart';
 import 'log_service.dart';

class PermissionService {
  final _log = LogService();

  // 检查并请求所有必要的权限
  Future<Map<Permission, PermissionStatus>> checkAndRequestPermissions() async {
    if (!PlatformUtils.isIOS && !PlatformUtils.isAndroid) {
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
  List<Permission> _getRequiredPermissions() {
    if (PlatformUtils.isIOS) {
      return [
        // iOS 不需要网络权限（网络是默认的）
        // 但需要本地网络权限（iOS 14+）
        Permission.photos, // 相册权限（可选）
        Permission.camera, // 相机权限（可选）
        Permission.notification, // 通知权限（可选）
      ];
    } else if (PlatformUtils.isAndroid) {
      return [
        Permission.storage, // 存储权限
        Permission.photos, // 相册权限
        Permission.camera, // 相机权限
        Permission.notification, // 通知权限
      ];
    }
    return [];
  }

  // 检查权限状态
  Future<Map<Permission, PermissionStatus>> _checkPermissions(
    List<Permission> permissions,
  ) async {
    final statuses = <Permission, PermissionStatus>{};
    for (final permission in permissions) {
      try {
        statuses[permission] = await permission.status;
      } catch (e) {
        _log.warning('检查权限失败', {
          'permission': permission.toString(),
          'error': e.toString(),
        });
        statuses[permission] = PermissionStatus.denied;
      }
    }
    return statuses;
  }

  // 请求权限
  Future<Map<Permission, PermissionStatus>> _requestPermissions(
    List<Permission> permissions,
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
  Future<bool> checkPermission(Permission permission) async {
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
  Future<PermissionStatus> requestPermission(Permission permission) async {
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
      return PermissionStatus.denied;
    }
  }

  // 打开应用设置
  Future<bool> openSettings() async {
    _log.info('打开应用设置');
    return await openAppSettings();
  }

  // 获取权限描述（用于UI显示）
  String getPermissionDescription(Permission permission) {
    if (permission == Permission.photos) {
      return '相册访问权限用于选择和分享图片';
    } else if (permission == Permission.camera) {
      return '相机权限用于拍摄照片';
    } else if (permission == Permission.notification) {
      return '通知权限用于接收重要消息提醒';
    } else if (permission == Permission.storage) {
      return '存储权限用于保存和读取文件';
    }
    return '此权限用于应用正常运行';
  }

  // 获取权限名称
  String getPermissionName(Permission permission) {
    if (permission == Permission.photos) {
      return '相册';
    } else if (permission == Permission.camera) {
      return '相机';
    } else if (permission == Permission.notification) {
      return '通知';
    } else if (permission == Permission.storage) {
      return '存储';
    }
    return permission.toString().split('.').last;
  }
}
