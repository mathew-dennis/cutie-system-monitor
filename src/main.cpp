#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlEngine>
#include <QJSEngine>
#include <QTranslator>

#include "systemmonitor.h"

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
