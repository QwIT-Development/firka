import 'package:firka/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../helpers/api/client/kreta_client.dart';
import '../../../helpers/api/consts.dart';
import '../../../helpers/api/token_grant.dart';
import '../../../helpers/db/models/token_model.dart';
import '../../../helpers/firka_state.dart';
import '../screens/home/home_screen.dart';

class LoginWebviewWidget extends StatefulWidget {
  final AppInitialization data;
  final String? username;
  final String? schoolId;

  const LoginWebviewWidget(this.data,
      {super.key, this.username, this.schoolId});

  @override
  State<LoginWebviewWidget> createState() => _LoginWebviewWidgetState();
}

class _LoginWebviewWidgetState extends FirkaState<LoginWebviewWidget> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    var loginUrl = KretaEndpoints.kretaLoginUrl;

    if (widget.username != null && widget.schoolId != null) {
      loginUrl = KretaEndpoints.kretaLoginUrlRefresh(
          widget.username!, widget.schoolId!);
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(loginUrl))
      ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
        var uri = Uri.parse(request.url);

        if (uri.path == "/ellenorzo-student/prod/oauthredirect") {
          if (kDebugMode) {
            print("query params: ${uri.queryParameters}");
          }

          var code = uri.queryParameters["code"]!;

          try {
            var isar = widget.data.isar;
            var resp = await getAccessToken(code);

            if (kDebugMode) {
              print("getAccessToken(): $resp");
            }

            var tokenModel = TokenModel.fromResp(resp);

            await isar.writeTxn(() async {
              await isar.tokenModels.put(tokenModel);
            });

            widget.data.client = KretaClient(tokenModel, isar);
            widget.data.tokenCount = await isar.tokenModels.count();

            if (!mounted) return NavigationDecision.prevent;

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (context) => HomeScreen(widget.data, false)),
              (route) => false, // Remove all previous routes
            );
          } catch (ex) {
            if (kDebugMode) {
              print("oauthredirect failed: $ex");
            }
            // TODO: display an error popup
          }

          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      }));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.90,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFB9C8E5),
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                      width: 40,
                      height: 4,
                    ),
                  ),
                ],
              ),
              Container(
                height: MediaQuery.of(context).size.height * 0.8,
                // Adjust height for content
                margin: const EdgeInsets.symmetric(horizontal: 16),
                // Add ClipRRect for circular edges
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: WebViewWidget(
                    controller: _webViewController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
