import QtQuick 2.0
import Sailfish.Silica 1.0

MenuItem {
    text: qsTr("Overview")
    onClicked: {
        var home = pageStack.find(function (page) {
            return page.objectName === "overview"
        })
        if (home) {
            pageStack.pop(home)
        }
    }
}
