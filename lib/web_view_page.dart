// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WebView.platform = SurfaceAndroidWebView();
    } else {
      WebView.platform = CupertinoWebView();
    }
  }

  late String _localPath;
  late bool _permissionReady;

  
  Future<void> _prepareSaveDir() async {
    _localPath = (await _findLocalPath())!;

    final savedDir = Directory(_localPath);
    bool hasExisted = await savedDir.exists();
    if (!hasExisted) {
      savedDir.create();
    }
  }

  Future<String?> _findLocalPath() async {
    //if (platform == TargetPlatform.android) {
    // return "/sdcard/Download";
    //} else {
    var directory = await getApplicationDocumentsDirectory();
    return '${directory.path}${Platform.pathSeparator}Download';
    //}
  }

  
  Future<bool> _checkPermission() async {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
      return true;
  }

  Future downloadURL(String url) async {
    _permissionReady = await _checkPermission();
    if (_permissionReady) {
      await _prepareSaveDir();
      printW("Status Downloading");
      try {
        final String agora = DateTime.now().toString();
        String arquivo = "arquivo_${agora}";

        await Dio().download(url,"$_localPath/$arquivo.docx");
        printW("Download Completed");

        printW("Open File ${"$_localPath/$arquivo.docx"}");
        final String fileName = "$_localPath/$arquivo.docx";
        await OpenFilex.open(fileName);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Center(
            child: Text('Erro ao salvar arquivo'),
          )),
        );
        printW("Erro download");
      }
  }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return false;
        } else {
          bool shouldExit = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Deseja realmente sair da NAV?'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: const Text('Sair'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                  ),
                ],
              );
            },
          );
          // Retorna o valor obtido do AlertDialog.
          return shouldExit;
        }
      },
      child: Scaffold(
        body: Builder(builder: (BuildContext context) {
          return WebView(
            debuggingEnabled: true,
            initialUrl: 'https://preview-pr-169--nav-trivento.netlify.app/login',
            //initialUrl: 'https://aluno.triventoeducacao.com.br',
            allowsInlineMediaPlayback: true,
            initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
            javascriptMode: JavascriptMode.unrestricted,
            zoomEnabled: false,
            onWebViewCreated: (WebViewController webViewController) {
              controller = webViewController;
              printW("onWebViewCreated");
            },
            onProgress: (int progress) {
              // printW('WebView is loading (progress : $progress%)');
            },
            javascriptChannels: <JavascriptChannel>{
              JavascriptChannel(
                  name: 'Toaster',
                  onMessageReceived: (JavascriptMessage message) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message.message)),
                    );
                  },)
            },
            navigationDelegate: (NavigationRequest request) {
              /*
               if (request.url.startsWith('http')) {
                printW('blocking navigation to $request}');
                return NavigationDecision.navigate;
              }*/
              downloadURL(request.url);
              //return NavigationDecision.navigate;
              return NavigationDecision.prevent;
            },
            onPageStarted: (String url) {
              printW('Page started loading: $url');
            },
            onPageFinished: (String url) {
              printW('onPageFinished: $url');
            },
            onWebResourceError: (error) {
              printW("onWebResourceError: $error");
            },
            gestureNavigationEnabled: true,
            backgroundColor: const Color(0x0000293b),
            geolocationEnabled: false,
          );
        }),
      ),
    );
  }
}

void printW(text) {
  if (kDebugMode) {
    print('\x1B[33m$text\x1B[0m');
  }
}
