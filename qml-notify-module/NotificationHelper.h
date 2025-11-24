#ifndef NOTIFICATIONHELPER_H
#define NOTIFICATIONHELPER_H

#include <QObject>
#include <QString>
#include <QDBusConnection>
#include <QJsonObject>

class NotificationHelper : public QObject
{
Q_PROPERTY(QString push_app_id READ get_push_app_id WRITE set_push_app_id)
Q_OBJECT
public:
    
    explicit NotificationHelper(QObject *parent = 0);

    //Send a notification from title and message information
    Q_INVOKABLE void showNotificationMessage(const QString &title,const QString &message);
    
    //Update notification counter on icon
    Q_INVOKABLE bool updateCount(const int count);
    
    // Send a notification based on JSON notification
    bool sendJSON(const QJsonObject &message);
    
    QString get_push_app_id();
    void set_push_app_id(QString value);

private:
    QJsonObject buildSummaryMessage(const QString &title,const QString &message);
    QByteArray makePath(const QString &appId);

    QDBusConnection m_conn;
    QStringList m_tags;
    QString push_app_id;
};

#endif // NOTIFICATIONHELPER_H
 
