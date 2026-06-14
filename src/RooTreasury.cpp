#include <sailfishapp.h>
#include <QGuiApplication>
#include <QLocale>
#include <QQmlContext>
#include <QQuickView>
#include <QTranslator>
#include "BackupHelper.h"

int main(int argc, char *argv[])
{
    QGuiApplication *app = SailfishApp::application(argc, argv);
    app->setApplicationName("RooTreasury");
    app->setApplicationVersion("1.0");

    QTranslator *fallbackTranslator = new QTranslator(app);
    const QString localeName = QLocale::system().name().toLower();
    if (!localeName.startsWith("it")) {
        const QString translationsPath = SailfishApp::pathTo("qml/translations").toLocalFile();
        if (fallbackTranslator->load("RooTreasury_en", translationsPath)) {
            app->installTranslator(fallbackTranslator);
        }
    }

    QQuickView *view = SailfishApp::createView();
    BackupHelper backupHelper;
    view->rootContext()->setContextProperty("backupHelper", &backupHelper);
    view->setSource(SailfishApp::pathTo("qml/RooTreasury.qml"));
    view->show();

    return app->exec();
}
