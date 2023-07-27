// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';

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
    }
  }


Future<void> downloadBlob(String blobUrl) async {
  try {
    final response = await http.get(Uri.https(blobUrl));
    if (response.statusCode == 200) {
      // Content downloaded successfully.
      Uint8List content = response.bodyBytes;
    } else {
      // Handle error response.
      printW('Failed to download blob. Status code: ${response.statusCode}');
    }
  } catch (e) {
    printW('B');
    printW('$blobUrl');
    
  }
}


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        printW("onWillPop2");
         if (await controller.canGoBack()) {
            await controller.goBack();
            return false;
          } else {
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deseja sair da NAV ? ')),
            );
            return true;
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
            onWebViewCreated: (WebViewController webViewController) {
              printW("onWebViewCreated");
              controller = webViewController;
              //_controller.complete(webViewController);
            },
            onProgress: (int progress) {
              // printW('WebView is loading (progress : $progress%)');
            },
            javascriptChannels: <JavascriptChannel>{
              JavascriptChannel(
                name: 'Toaster',
                onMessageReceived: (JavascriptMessage message) {
                  // ignore: deprecated_member_use
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message.message)),
                  );
                })
            },
            navigationDelegate: (NavigationRequest request) {
              // if (request.url.startsWith('https://www.youtube.com/')) {
              //   print('blocking navigation to $request}');
              //   return NavigationDecision.prevent;
              // }
              
              downloadBlob(request.url);
              
              // if (!await launchUrl(Uri.parse("$request"))) {
              //   throw Exception('Could not launch $request');
              // }
              return NavigationDecision.prevent;
            },
            onPageStarted: (String url) {
              print('Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Page finished loading: $url');
            },
            gestureNavigationEnabled: true,
            backgroundColor: const Color(0x00000000),
            geolocationEnabled: true, // set geolocationEnable true or not
          );
        }),
      ),
    );
  }
}

 void printW(text) {
  print('\x1B[33m$text\x1B[0m');
}