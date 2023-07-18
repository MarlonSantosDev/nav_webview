// ignore_for_file: avoid_print, unnecessary_this
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  PullToRefreshController? pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

   late String _localPath;
  late bool _permissionReady;
  late TargetPlatform? platform;


  @override
  void initState() {
    super.initState();
    inicio();
    
    pullToRefreshController = kIsWeb ? null : PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.red,
      ),
      onRefresh: () async {
        printW("onRefresh");
        if (defaultTargetPlatform == TargetPlatform.android) {
          webViewController?.reload();
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  inicio() async {
    printW("Inicio");
    await Permission.storage.request();
    await Permission.camera.request();
    await Permission.audio.request();
    await Permission.videos.request();
    await Permission.microphone.request();
     if (Platform.isAndroid) {
      platform = TargetPlatform.android;
    } else {
      platform = TargetPlatform.iOS;
    }
  }

  Future<bool> _checkPermission() async {
    if (platform == TargetPlatform.android) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        if (result == PermissionStatus.granted) {
          return true;
        }
      } else {
        return true;
      }
    } else {
      return true;
    }
    return false;
  }

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
      var directory = await getLibraryDirectory();
      return '${directory.path}${Platform.pathSeparator}Download';
    }

   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("1"),
        actions: [
          IconButton(
            onPressed: (){
              webViewController?.goBack();
              //webViewController?.goForward();
              //webViewController?.reload();
              printW("onPressed reload");
            },
            icon: const Icon(Icons.replay_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(
                url: WebUri(
                  "https://aluno.triventoeducacao.com.br/login",
                  //"https://staging--nav-trivento.netlify.app/login",
                ),
              ),
              initialOptions: InAppWebViewGroupOptions(
                crossPlatform: InAppWebViewOptions(
                  useOnLoadResource: true,
                  preferredContentMode: UserPreferredContentMode.MOBILE,
                  //useShouldInterceptAjaxRequest: true,
                  //useShouldInterceptFetchRequest: true,
                  //mediaPlaybackRequiresUserGesture: true,
                  useOnDownloadStart: true,
                  javaScriptEnabled: true,
                  javaScriptCanOpenWindowsAutomatically: true,
                  allowUniversalAccessFromFileURLs: true,
                  allowFileAccessFromFileURLs: true,
                  useShouldOverrideUrlLoading: true,
                )
              ),
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onDownloadStartRequest: (controller, url) async {
                printW("onDownloadStartRequest");
                 _permissionReady = await _checkPermission();
                      if (_permissionReady) {
                        await _prepareSaveDir();
                        printW("Status Downloading");
                        try {
                          final DateTime now = DateTime.now();
                          final DateFormat formatter = DateFormat('dd-MM-yyyy-HH-mm-ss');
                          String arquivo = "PDF_${formatter.format(now)}";

                          
                          String u = "${url.url}";
                          printW("Antes: |$u|");
                          u = u.replaceAll('blob:', '') ;
                          printW("Depois: |$u|");

                          await Dio().download(
                            u,
                            "$_localPath/$arquivo.pdf",
                            onReceiveProgress: (int a, int b) {
                              setState(() {
                                printW('Recebendo: ${b.toStringAsFixed(0)} do total : ${a.toStringAsFixed(0)}\n');
                                printW(((a / b) * 100).toStringAsFixed(0));
                              });
                            },
                          );
                          printW("Download Completed");

                          printW("Open File");
                          final String fileName = "$_localPath/$arquivo.pdf";
                          await OpenFilex.open(fileName);
                          printW("Fim\n");
                          printW("URL: ${url.url}\n");
                          printW("Arquivo: $fileName\n");
                        } catch (e) {
                          printW("Download Failed. \n$e|");
                        }
                      }
              },
              onLoadStart: (controller, url) {
                printW("onLoadStart");
                setState(() {
                  this.url = url.toString();
                  urlController.text = this.url;
                });
              },
              /*
                  onPermissionRequest: (controller, request) async {
                    return PermissionResponse(
                        resources: request.resources,
                        action: PermissionResponseAction.GRANT);
                  },*/
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                printW("shouldOverrideUrlLoading");
                var uri = navigationAction.request.url!;

                if (![
                  "http",
                  "https",
                  "file",
                  "chrome",
                  "data",
                  "javascript",
                  "about"
                ].contains(uri.scheme)) {
                  if (await canLaunchUrl(uri)) {
                    // Launch the App
                    await launchUrl(
                      uri,
                    );
                    // and cancel the request
                    return NavigationActionPolicy.CANCEL;
                  }
                }

                return NavigationActionPolicy.ALLOW;
              },
              onLoadStop: (controller, url) async {
                printW("onLoadStop");
                pullToRefreshController?.endRefreshing();
                setState(() {
                  this.url = url.toString();
                  urlController.text = this.url;
                });
              },
              /*
                  onReceivedError: (controller, request, error) {
                    pullToRefreshController?.endRefreshing();
                  },*/
              onProgressChanged: (controller, progress) {
                printW("onProgressChanged");
                if (progress == 100) {
                  pullToRefreshController?.endRefreshing();
                }
                setState(() {
                  this.progress = progress / 100;
                  urlController.text = this.url;
                });
              },
              onUpdateVisitedHistory: (controller, url, androidIsReload) {
                printW("onUpdateVisitedHistory");
                setState(() {
                  this.url = url.toString();
                  urlController.text = this.url;
                });
              },
              onConsoleMessage: (controller, consoleMessage) {
                //printW("onConsoleMessage");
                //printW(consoleMessage);
              },
            ),
            progress < 1.0
                ? LinearProgressIndicator(value: progress)
                : Container(),
          ],
        ),
      ),
    );
  }
}

 void printW(text) {
    print('\x1B[33m$text\x1B[0m');
  }