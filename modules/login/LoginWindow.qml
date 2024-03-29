import QtQuick 2.0
import QtQuick.Window 2.0
import QtWebKit 3.0

import "qrc:/js/URLQuery.js" as URLQuery

Window {
    id: loginWindow

    width: 1024
    height: 768

    visible: false

    property string appId
    property string permissions
    property var finishRegExp: /^https:\/\/oauth.vk.com\/blank.html/

    signal succeeded(string token, string userId)
    signal failed(string error)

    function login() {
        var params = {
            client_id: loginWindow.appId,
            display: "popup",
            response_type: "token",
            redirect_uri: 'http://oauth.vk.com/blank.html'
        }

        if (permissions) {
            params.scope = permissions;
        }

        webView.url = "https://oauth.vk.com/authorize?%1".arg(URLQuery.serializeParams(params));
    }

    WebView {
        id: webView

        anchors.fill: parent

        onLoadingChanged: {
            console.log(loadRequest.url.toString());

            if (loadRequest.status === WebView.LoadFailedStatus) {
                loginWindow.failed("Loading error:", loadRequest.errorDomain, loadRequest.errorCode, loadRequest.errorString);
                return;
            } else if (loadRequest.status === WebView.LoadStartedStatus) {
                return;
            }

            if (!finishRegExp.test(loadRequest.url.toString())) {
                return;
            }

            var result = URLQuery.parseParams(loadRequest.url.toString());
            if (!result) {
                loginWindow.failed("Wrong responce from server", loadRequest.url.toString())
                return
            }
            if (result.error) {
                loginWindow.failed("Error", result.error, result.error_description)
                return
            }
            if (!result.access_token) {
                loginWindow.failed("Access token absent", loadRequest.url.toString())
                return
            }

            succeeded(result.access_token, result.user_id);
            return;
        }
    }
}

