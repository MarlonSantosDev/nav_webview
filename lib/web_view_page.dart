// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

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

  Future downloadURL(String url) async {
    printW("url: $url");
    try {
      final String agora = DateTime.now().toString();
      String arquivo = "_$agora";
      await Dio().download(
        url,
        "$getDownloadsDirectory()/nav_$arquivo.pdf",
        onReceiveProgress: (int a, int b) {
          setState(() {
            printW(
                'Recebendo: ${b.toStringAsFixed(0)} do total : ${a.toStringAsFixed(0)}\n');
          });
        },
      );
      printW("Download Feito");
      await OpenFilex.open("$getDownloadsDirectory()/nav_$arquivo.pdf");
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo salvo arquivo')),
        );
      printW("Erro no download");
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
            initialUrl: 'https://aluno.triventoeducacao.com.br',
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
                  })
            },
            navigationDelegate: (NavigationRequest request) {
              downloadURL(request.url);
              //return NavigationDecision.navigate;
              return NavigationDecision.prevent;
            },
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
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
