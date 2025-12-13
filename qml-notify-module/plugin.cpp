#include <qqml.h>
#include <QQmlExtensionPlugin>
#include "NotificationHelper.h"

class NotificationsPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "org.qt-project.Qt.QQmlExtensionInterface")

public:
    void registerTypes(const char *uri) override
    {
        // Doit correspondre au module indiqué dans qmldir
        Q_ASSERT(uri == QStringLiteral("Pparent.Notifications"));
        qmlRegisterType<NotificationHelper>(uri, 1, 0, "NotificationHelper");
    }
};

#include "plugin.moc"
