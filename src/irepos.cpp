#include <QGuiApplication>
#include <QQmlContext>
#include <QQuickView>
#include <QScopedPointer>

#include <sailfishapp.h>

#include "credentials.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));

    // Before the view, so it is read for the first refresh and outlives the view.
    Credentials credentials;

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->rootContext()->setContextProperty(QStringLiteral("credentials"), &credentials);
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
}
