/// 统一的应用错误分类
enum AppErrorType {
  /// 网络错误（正常是不可修复的）
  network,
  
  /// 超时错误（可以重试）
  timeout,
  
  /// 数据解析失败
  parsing,
  
  /// 数据验证失败
  validation,
  
  /// 本地存储数据失败
  storage,
  
  /// API 数据类型错误
  apiError,
  
  /// 未知错误
  unknown,
}

/// 应用全局错误类
class AppError implements Exception {
  final AppErrorType type;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.type,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  /// 获取用户友好的错误提示文本
  String get userFriendlyMessage {
    switch (type) {
      case AppErrorType.network:
        return '网络连接失败，请检查你的网络设置';
      case AppErrorType.timeout:
        return '请求超时，请上网速度慢时稍后重试';
      case AppErrorType.parsing:
        return '数据格式不正常，请重新加载';
      case AppErrorType.validation:
        return '输入的数据有误，请检查需要填写的内容';
      case AppErrorType.storage:
        return '本地存储数据失败，请重新启动应用';
      case AppErrorType.apiError:
        return 'API 调用失败，请稍后重试';
      case AppErrorType.unknown:
        return '发生未知错误，请联系技术支持';
    }
  }

  /// 获取错误的详细描述
  String get detailedMessage =>
      message.isNotEmpty ? message : userFriendlyMessage;

  @override
  String toString() => 'AppError($type): $detailedMessage';
}

/// 类型安全的错误处理结果
class Result<T> {
  final T? data;
  final AppError? error;
  final bool isSuccess;

  Result._success(this.data)
      : error = null,
        isSuccess = true;

  Result._error(this.error)
      : data = null,
        isSuccess = false;

  factory Result.success(T data) => Result._success(data);
  factory Result.error(AppError error) => Result._error(error);

  R fold<R>(
    R Function(AppError) onError,
    R Function(T) onSuccess,
  ) {
    if (isSuccess) {
      return onSuccess(data as T);
    } else {
      return onError(error as AppError);
    }
  }
}
