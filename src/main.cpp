#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QJSEngine>
#include <QTranslator>

// 1. Include the headers for your sub-classes
#include "systemmonitor.h"
#include "cpu.h"
#include "meminfo.h"
#include "wifiinfo.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    QGuiApplication app(argc, argv);

    QString locale = QLocale::system().name();
    QTranslator translator;
    (void)translator.load(QString(":/i18n/cutie-sysmonitor_") + locale);
    app.installTranslator(&translator);

    // 2. Register the sub-classes so QML understands their properties
    qmlRegisterUncreatableType<CpuInfo>("Cutie.SysMonitor", 1, 0, "CpuInfo", "Managed by SystemMonitor");
    qmlRegisterUncreatableType<MemoryInfo>("Cutie.SysMonitor", 1, 0, "MemoryInfo", "Managed by SystemMonitor");
    qmlRegisterUncreatableType<WifiInfo>("Cutie.SysMonitor", 1, 0, "WifiInfo", "Managed by SystemMonitor");

    // (Keep your existing SystemMonitor singleton registration)
    qmlRegisterSingletonType<SystemMonitor>(
        "Cutie.SysMonitor", 1, 0, "SysMonitor",
        [](QQmlEngine *, QJSEngine *) -> QObject * {
            return new SystemMonitor();
        });

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
