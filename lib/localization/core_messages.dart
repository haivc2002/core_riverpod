import 'package:core_flutter/common/k.dart';
import 'package:flutter/material.dart';

class GlobalCoreMessagesLocalizations extends LocalizationsDelegate<CoreMessages> {
  const GlobalCoreMessagesLocalizations();

  static const LocalizationsDelegate<CoreMessages> delegate = GlobalCoreMessagesLocalizations();

  static final Map<String, CoreMessages> _modules = {
    K.vi: _ViMessages(),
    K.en: _EnMessages(),
    K.zh: _ZhMessages(),
    K.ja: _JaMessages(),
    K.ko: _KoMessages(),
    K.es: _EsMessages(),
    K.fr: _FrMessages(),
  };

  @override
  bool isSupported(Locale locale) => _modules.containsKey(locale.languageCode);

  @override
  Future<CoreMessages> load(Locale locale) async {
    return _modules[locale.languageCode] ?? _EnMessages();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<CoreMessages> old) => false;
}

abstract class CoreMessages {
  static CoreMessages of(BuildContext context) {
    return Localizations.of<CoreMessages>(context, CoreMessages) ?? _EnMessages();
  }

  String get networkDisconnected => '';
  String get networkTimeout => '';
  String get unknownError => '';
  String get noServerResponse => '';
  String get serverBusy => '';
  String get serverError => '';
  String get close => '';
  String get success => '';
  String get notification => '';
  String get failure => '';
}

class _ViMessages implements CoreMessages {
  @override
  String get networkDisconnected => 'Không có kết nối mạng, vui lòng kiểm tra lại!';
  @override
  String get networkTimeout => 'Kết nối tới máy chủ bị quá hạn';
  @override
  String get unknownError => 'Đã có lỗi xảy ra!';
  @override
  String get noServerResponse => 'Không nhận được phản hồi từ máy chủ';
  @override
  String get serverBusy => 'Hệ thống đang bận';
  @override
  String get serverError => 'Đã xảy ra lỗi từ máy chủ';
  @override
  String get close => 'Đóng';
  @override
  String get success => 'Thành công';
  @override
  String get notification => 'Thông báo';
  @override
  String get failure => 'Thất bại';
}

class _EnMessages implements CoreMessages {
  @override
  String get networkDisconnected => 'No network connection, please check again!';
  @override
  String get networkTimeout => 'Connection to server timed out';
  @override
  String get unknownError => 'An error occurred!';
  @override
  String get noServerResponse => 'No response from the server';
  @override
  String get serverBusy => 'System is busy';
  @override
  String get serverError => 'A server error occurred';
  @override
  String get close => 'Close';
  @override
  String get success => 'Success';
  @override
  String get notification => 'Notification';
  @override
  String get failure => 'Failure';
}

class _ZhMessages implements CoreMessages {
  @override
  String get networkDisconnected => '没有网络连接，请检查！';
  @override
  String get networkTimeout => '与服务器的连接已超时。';
  @override
  String get unknownError => '发生错误！';
  @override
  String get noServerResponse => '服务器没有响应';
  @override
  String get serverBusy => '系统繁忙';
  @override
  String get serverError => '服务器发生错误';
  @override
  String get close => '关闭';
  @override
  String get success => '成功';
  @override
  String get notification => '通知';
  @override
  String get failure => '失败';
}

class _JaMessages implements CoreMessages {
  @override
  String get networkDisconnected => 'ネットワーク接続がありません。確認してください。';
  @override
  String get networkTimeout => 'サーバーへの接続がタイムアウトしました';
  @override
  String get unknownError => 'エラーが発生しました！';
  @override
  String get noServerResponse => 'サーバーからの応答がありません';
  @override
  String get serverBusy => 'システムがビジー状態です';
  @override
  String get serverError => 'サーバーエラーが発生しました';
  @override
  String get close => '閉じる';
  @override
  String get success => '成功';
  @override
  String get notification => '通知';
  @override
  String get failure => '失敗';
}

class _KoMessages implements CoreMessages {
  @override
  String get networkDisconnected => '네트워크 연결이 없습니다. 다시 확인해 주세요!';
  @override
  String get networkTimeout => '서버 연결 시간이 초과되었습니다.';
  @override
  String get unknownError => '오류가 발생했습니다!';
  @override
  String get noServerResponse => '서버 응답이 없습니다';
  @override
  String get serverBusy => '시스템이 사용 중입니다';
  @override
  String get serverError => '서버 오류가 발생했습니다';
  @override
  String get close => '닫기';
  @override
  String get success => '성공';
  @override
  String get notification => '알림';
  @override
  String get failure => '실패';
}

class _EsMessages implements CoreMessages {
  @override
  String get networkDisconnected => '¡No hay conexión a internet, por favor verifique!';
  @override
  String get networkTimeout => 'Tiempo de conexión al servidor agotado.';
  @override
  String get unknownError => '¡Ha ocurrido un error!';
  @override
  String get noServerResponse => 'No hay respuesta del servidor';
  @override
  String get serverBusy => 'El sistema está ocupado';
  @override
  String get serverError => 'Ocurrió un error en el servidor';
  @override
  String get close => 'Cerrar';
  @override
  String get success => 'Éxito';
  @override
  String get notification => 'Notificación';
  @override
  String get failure => 'Fallo';
}

class _FrMessages implements CoreMessages {
  @override
  String get networkDisconnected => 'Pas de connexion réseau, veuillez vérifier !';
  @override
  String get networkTimeout => 'Le délai de connexion au serveur a expiré.';
  @override
  String get unknownError => 'Une erreur s\'est produite !';
  @override
  String get noServerResponse => 'Pas de réponse du serveur';
  @override
  String get serverBusy => 'Le système est occupé';
  @override
  String get serverError => 'Une erreur de serveur s\'est produite';
  @override
  String get close => 'Fermer';
  @override
  String get success => 'Succès';
  @override
  String get notification => 'Notification';
  @override
  String get failure => 'Échec';
}
