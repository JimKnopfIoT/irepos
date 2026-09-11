import QtQuick 2.0
import Sailfish.Silica 1.0
import "../components"

// The publisher's name, and the login that unlocks their own statistics.
Page {
    id: page

    property bool looking: false
    property string message: ""

    allowedOrientations: Orientation.All

    function apply() {
        var name = nameField.text.trim()
        if (name.length === 0) {
            return
        }
        page.looking = true
        page.message = ""
        Figures.findPublisher(name, function (owner) {
            page.looking = false
            page.message = qsTr("Found: %1").arg(owner)
        }, function (reason) {
            page.looking = false
            page.message = reason === "offline"
                    ? qsTr("No connection.")
                    : qsTr("Not found — check the spelling.")
        })
    }

    // Both fields are emptied before anything is sent.
    function signIn() {
        var name = loginField.text.trim()
        var password = secretField.text
        loginField.text = ""
        secretField.text = ""
        if (Clipboard.hasText && Clipboard.text === password) {
            Clipboard.text = ""
        }
        loginField.focus = false
        secretField.focus = false
        if (name.length === 0 || password.length === 0) {
            return
        }
        page.message = ""
        Figures.signIn(name, password, function (ok, detail, kept) {
            if (!ok) {
                page.message = detail
            } else if (!kept) {
                page.message = qsTr("Signed in as %1, but the login could not be "
                                    + "kept: %2").arg(detail).arg(credentials.problem)
            } else {
                page.message = qsTr("Signed in as %1. The login is kept.").arg(detail)
            }
        })
        password = ""
    }

    function signOut() {
        Figures.signOut()
        page.message = credentials.stored
                ? qsTr("The login could not be deleted: %1").arg(credentials.problem)
                : qsTr("Signed out, login deleted.")
    }

    onStatusChanged: {
        if (status !== PageStatus.Active) {
            secretField.text = ""
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (!Qt.application.active) {
                secretField.text = ""
            }
        }
    }

    RemorsePopup { id: remorse }

    Backdrop { }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            HomeItem { }
        }

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Settings") }

            TextField {
                id: nameField

                width: parent.width
                label: qsTr("OpenRepos name")
                placeholderText: qsTr("OpenRepos name")
                text: Figures.owner
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: page.apply()
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.looking ? qsTr("Looking…") : qsTr("Apply")
                enabled: !page.looking && nameField.text.trim().length > 0
                onClicked: page.apply()
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                visible: page.message.length > 0
                text: page.message
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            DetailItem {
                label: qsTr("Publisher id")
                value: Figures.userId.length > 0 ? Figures.userId : "—"
            }

            DetailItem {
                label: qsTr("Days of history")
                value: String(Figures.days)
            }

            SectionHeader { text: qsTr("Publisher account") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("Without signing in these are the public figures every "
                           + "Storeman reads: one total per app, and a history "
                           + "that starts the day this was installed. Signed in, "
                           + "the site hands over what it keeps for the owner — "
                           + "every app's download history day by day, and the "
                           + "countries the downloads came from.")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                text: qsTr("The login is kept in the device's secrets storage, "
                           + "encrypted and bound to the device lock, and used "
                           + "to sign in again on every start. Both fields are "
                           + "emptied as soon as they are sent; to change the "
                           + "login, sign in again.")
            }

            DetailItem {
                label: qsTr("Kept login")
                value: credentials.stored ? credentials.login : qsTr("none")
            }

            DetailItem {
                label: qsTr("Session")
                value: Figures.signedIn ? qsTr("signed in") : qsTr("not signed in")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Tint.red
                visible: credentials.problem.length > 0
                text: qsTr("Secrets storage: %1").arg(credentials.problem)
            }

            TextField {
                id: loginField

                width: parent.width
                label: qsTr("OpenRepos login")
                placeholderText: qsTr("OpenRepos login")
                inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: secretField.focus = true
            }

            PasswordField {
                id: secretField

                width: parent.width
                label: qsTr("Password")
                placeholderText: qsTr("Password")
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData
                                  | Qt.ImhNoAutoUppercase
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: page.signIn()
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Figures.signingIn ? qsTr("Signing in…")
                    : credentials.stored ? qsTr("Replace login")
                                         : qsTr("Sign in")
                enabled: !Figures.signingIn
                         && loginField.text.trim().length > 0
                         && secretField.text.length > 0
                onClicked: page.signIn()
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Sign out and delete login")
                visible: credentials.stored || Figures.signedIn
                onClicked: remorse.execute(qsTr("Deleting login"),
                                           function () { page.signOut() })
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }
        }

        VerticalScrollDecorator { }
    }
}
