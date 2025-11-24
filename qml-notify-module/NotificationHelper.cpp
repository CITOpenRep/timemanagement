#include "NotificationHelper.h"
#include <QDebug>
#include <QDBusInterface>
#include <QDBusReply>
#include <QPointer>
#include <QByteArray>
#include <QDBusMessage>
#include <QJsonDocument>
#include <QDebug>
#include <QJsonArray>

#define PUSH_SERVICE "com.lomiri.PushNotifications"
#define POSTAL_SERVICE "com.lomiri.Postal"
#define PUSH_PATH "/com/lomiri/PushNotifications"
#define POSTAL_PATH "/com/lomiri/Postal"
#define PUSH_IFACE "com.lomiri.PushNotifications"
#define POSTAL_IFACE "com.lomiri.Postal"



QJsonObject NotificationHelper::buildSummaryMessage(const QString &title,const QString &message) {


    QString appid=push_app_id.section('_', 0, 0);
    QString activityid=push_app_id.section('_', 1, 1);    
    QString icon = QString("/opt/click.ubuntu.com/")+appid+QString("/current/icon.png");

    QJsonObject c;
    c["summary"] = title;
    if (message.length()>0)
        c["body"] = message;
    c["popup"] = true;
    c["persist"] = true;
    c["icon"] = icon;
    QJsonArray actions = QJsonArray();
    QString actionUri = QStringLiteral("appid://")+appid+"/"+activityid+"/current-user-version";
    actions.append(actionUri);
    c["actions"] = actions;

    QJsonObject notification;
    notification["card"] = c;
    notification["sound"] = true;
    notification["vibrate"] = true;
    QJsonObject res;
    res["notification"] = notification;
    return res;
}


//shamelessly stolen from accounts-polld
bool NotificationHelper::sendJSON(const QJsonObject &message)
{
    QDBusMessage msg = QDBusMessage::createMethodCall(POSTAL_SERVICE,
                                                      makePath(push_app_id),
                                                      POSTAL_IFACE,
                                                      "Post");
    msg << push_app_id;
    QByteArray data = QJsonDocument(message).toJson(QJsonDocument::Compact);
    msg << QString::fromUtf8(data);

    qDebug() << "[POST] >>  " << msg;

    QDBusMessage reply = m_conn.call(msg);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        qDebug() << "[POST ERROR] " << reply.errorMessage();
        return false;
    }
    qDebug() << "[POST SUCCESS] >> Message posted.";
    QJsonObject n = message.value("notification").toObject();
    QString tag = n.value("tag").toString();
    return true;
}



bool NotificationHelper::updateCount(const int count)
{
    bool visible = count != 0;
    QDBusMessage message = QDBusMessage::createMethodCall(POSTAL_SERVICE,
                                                          makePath(push_app_id),
                                                          POSTAL_IFACE,
                                                          "SetCounter");
    message << push_app_id << count << visible;
    bool result = m_conn.send(message);
    if (result) {
        qDebug() << "[COUNT] >> Updated.";
    }
    return result;
    
}

//shamelessly stolen from accounts-polld
QByteArray NotificationHelper::makePath(const QString &appId)
{
    QByteArray path(QByteArrayLiteral("/com/lomiri/Postal/"));

    QByteArray pkg = appId.split('_').first().toUtf8();
    for (int i = 0; i < pkg.count(); i++) {
        char buffer[10];
        char c = pkg[i];
        switch (c) {
        case '+':
        case '.':
        case '-':
        case ':':
        case '~':
        case '_':
            sprintf(buffer, "_%.2x", c);
            path += buffer;
            break;
        default:
            path += c;
        }
    }
    qDebug() << "[PATH] >> " << path;
    return path;
}

NotificationHelper::NotificationHelper(QObject *parent) : QObject(parent),
    m_conn(QDBusConnection::sessionBus())
{

}


void NotificationHelper::showNotificationMessage(const QString &title,const QString &message)
{
    sendJSON(buildSummaryMessage(title,message));
}

QString NotificationHelper::get_push_app_id() 
{ return push_app_id; }
   
void NotificationHelper::set_push_app_id(QString value)
{ push_app_id = value; }
