// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webview_pro/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});
  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;
  late String _localPath;
  late bool _permissionReady;
  bool load = true, loadDownload = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      //WebView.platform = SurfaceAndroidWebView();
    } else if (Platform.isIOS) {
      // WebView.platform = CupertinoWebView();
    }
  }

  @override
  void dispose() {
    super.dispose();
    //controller;
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
    var directory = await getApplicationDocumentsDirectory();
    return '${directory.path}${Platform.pathSeparator}Download';
  }

  Future<bool> _checkPermission() async {
    /*
    final status = await Permission.storage.status;
    if (status != PermissionStatus.granted) {
      final result = await Permission.storage.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    } else {
      return true;
    }
    return false;
    */
    return true;
  }
  
String getExtensionFromContentType({required String contentType}) {

  if (contentType.contains('image/png')) {
    return 'png';
  } else if (contentType.contains('image/jpeg')) {
    return 'jpg';
  } else if (contentType.contains('image/gif')) {
    return 'gif';
  } else if (contentType.contains('application/pdf')) {
    return 'pdf';
  } else if (contentType.contains('application/msword') || contentType.contains('application/vnd.openxmlformats-officedocument.wordprocessingml.document')) {
    return 'docx';
  } else if (contentType.contains('application/vnd.ms-excel') || contentType.contains('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')) {
    return 'xlsx';
  } else if (contentType.contains('text/plain')) {
    return 'txt';
  } else {
    return 'unknown';
  }
}


  Future<void> downloadURL(String url) async {
    _permissionReady = await _checkPermission();
    if (_permissionReady) {
      setState(() {
        loadDownload = true;
      });
      await _prepareSaveDir();
      printW("Status Downloading");
      try {
        final response = await Dio().get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        final agora = DateTime.now().toString().replaceAll(" ", "_").replaceAll(":", "-").split(".")[0];
        final contentType = response.headers['content-type'];
        final extension = getExtensionFromContentType(contentType: contentType.toString());
        final arquivo = "Arquivo_$agora.$extension";
        final file = File("$_localPath/$arquivo");
        await file.writeAsBytes(response.data);
        printW("Download Completed");

        final fileName = "$_localPath/$arquivo";
        if (kDebugMode) {
          print(fileName);
        }
        await OpenFilex.open(fileName);
      } catch (e) {
        if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Center(
                child: Text('Erro ao salvar arquivo'),
              ),
            ),
          );
        }
        printW("Erro download");
      } finally{
        setState(() {
          loadDownload = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Center(
            child: Text('Permissão negada para salvar arquivos'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: WillPopScope(
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
            return shouldExit;
          }
        },
        child: Stack(
          children: [
            Scaffold(
              body:
                  WebView(
                debuggingEnabled: false,
                initialUrl: 'https://preview-pr-169--nav-trivento.netlify.app/login', // PARE TESTE
                //initialUrl: 'https://aluno.triventoeducacao.com.br', // PROD
                allowsInlineMediaPlayback: true,
                initialMediaPlaybackPolicy: AutoMediaPlaybackPolicy.always_allow,
                javascriptMode: JavascriptMode.unrestricted,
                zoomEnabled: false,
                gestureNavigationEnabled: true,
                backgroundColor: const Color(0x0000293b),
                geolocationEnabled: false,
                onWebViewCreated: (WebViewController webViewController) {
                  controller = webViewController;
                  printW("onWebViewCreated");
                },
                onProgress: (int progress) {
                  setState(() {
                    if (progress < 98 ) {
                      load = true;
                      loadDownload = false;
                    } else {
                      load = false;
                      loadDownload = false;
                    }  
                  });
                  printW('WebView is loading (progress : $progress%)');
                },
                javascriptChannels: <JavascriptChannel>{
                  JavascriptChannel(
                    name: 'Toaster',
                    onMessageReceived: (JavascriptMessage message) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message.message)),
                      );
                    },
                  ),
                },
                navigationDelegate: (NavigationRequest request) {
                  if (request.url.contains('amazonaws')) {
                    printW("Link ${request.url}");
                    downloadURL(request.url);
                    return NavigationDecision.prevent;
                  }
                  if (request.url.startsWith("https://api.whatsapp.com/") || request.url.startsWith("whatsapp://send/")) {
                    printW("Whatsapp | ${request.url}");
                    launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
                    //OpenFilex.open(request.url);                  
                    return NavigationDecision.prevent;
                  }
                  printW("ir ${request.url}");
                  return NavigationDecision.navigate;
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
              ),
            ),
            Visibility(
              visible: loadDownload,
              child: Container(
                color: Colors.transparent,
                child: const Center(
                  child: CircularProgressIndicator(
                    color:  Colors.white,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: load,
              child: const Padding(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Center(
                  child: LinearProgressIndicator(
                    color:  Color.fromARGB(255, 1, 43, 63),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void printW(text) {
  if (kDebugMode) {
    print('\x1B[33m$text\x1B[0m');
  }
}
