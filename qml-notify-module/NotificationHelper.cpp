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
#include <QProcess>
#include <QCoreApplication>
#include <QFileInfo>
#include <QFile>
#include <QDateTime>
#include <QDir>
#include <QThread>

#define PUSH_SERVICE "com.lomiri.PushNotifications"
#define POSTAL_SERVICE "com.lomiri.Postal"
#define PUSH_PATH "/com/lomiri/PushNotifications"
#define POSTAL_PATH "/com/lomiri/Postal"
#define PUSH_IFACE "com.lomiri.PushNotifications"
#define POSTAL_IFACE "com.lomiri.Postal"

// Heartbeat file constants
#define HEARTBEAT_FILE "/home/phablet/.daemon_heartbeat"
#define MAX_HEARTBEAT_AGE_SECS 300  // 5 minutes - allow time for slow syncs



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

void NotificationHelper::startDaemon()
{
    // Check if daemon is already running
    int exitCode = QProcess::execute("pgrep", QStringList() << "-f" << "python3.*daemon.py");
    if (exitCode == 0) {
        qDebug() << "Daemon already running.";
        return;
    }

    qDebug() << "Starting daemon...";
    
    // First, run the bootstrap/setup to ensure dependencies and autostart are configured
    QString bootstrapScript = "/opt/click.ubuntu.com/ubtms/current/src/daemon_bootstrap.py";
    QString startScript = "/opt/click.ubuntu.com/ubtms/current/start-daemon.sh";
    
    // Check if the start script exists
    QFileInfo checkFile(startScript);
    if (!checkFile.exists()) {
        qDebug() << "Start script not found at:" << startScript;
        
        // Try bootstrap directly
        QFileInfo bootstrapFile(bootstrapScript);
        if (bootstrapFile.exists()) {
            qDebug() << "Using bootstrap script directly";
            QProcess *process = new QProcess();
            process->setWorkingDirectory("/opt/click.ubuntu.com/ubtms/current");
            process->setProgram("python3");
            process->setArguments(QStringList() << bootstrapScript);
            bool success = process->startDetached();
            qDebug() << "Bootstrap daemon start result:" << success;
            return;
        }
        
        // Fall back to direct daemon start
        QString daemonPath = "/opt/click.ubuntu.com/ubtms/current/src/daemon.py";
        QProcess *process = new QProcess();
        process->setWorkingDirectory("/opt/click.ubuntu.com/ubtms/current");
        process->setProgram("python3");
        process->setArguments(QStringList() << daemonPath);
        bool success = process->startDetached();
        qDebug() << "Direct daemon start result:" << success;
        return;
    }
    
    // Start the daemon using the shell script (handles environment setup)
    bool success = QProcess::startDetached("/bin/bash", QStringList() << startScript);
    if (success) {
        qDebug() << "Daemon started successfully via start script";
    } else {
        qDebug() << "Failed to start daemon";
    }
}

bool NotificationHelper::isDaemonHealthy()
{
    // First check if process is running
    int exitCode = QProcess::execute("pgrep", QStringList() << "-f" << "python3.*daemon.py");
    if (exitCode != 0) {
        qDebug() << "Daemon process not found";
        return false;
    }
    
    // Check heartbeat file age
    QFileInfo heartbeatFile(HEARTBEAT_FILE);
    if (!heartbeatFile.exists()) {
        qDebug() << "Heartbeat file not found";
        return false;
    }
    
    QDateTime lastModified = heartbeatFile.lastModified();
    qint64 ageSecs = lastModified.secsTo(QDateTime::currentDateTime());
    
    if (ageSecs > MAX_HEARTBEAT_AGE_SECS) {
        qDebug() << "Daemon heartbeat stale:" << ageSecs << "seconds old";
        return false;
    }
    
    qDebug() << "Daemon healthy, heartbeat age:" << ageSecs << "seconds";
    return true;
}

void NotificationHelper::ensureDaemonRunning()
{
    // First check if daemon process is running at all
    int exitCode = QProcess::execute("pgrep", QStringList() << "-f" << "python3.*daemon.py");
    
    if (exitCode == 0) {
        // Daemon process is running, don't kill it - just log status
        qDebug() << "Daemon process is running";
        
        // Optional: check heartbeat for logging purposes only
        QFileInfo heartbeatFile(HEARTBEAT_FILE);
        if (heartbeatFile.exists()) {
            QDateTime lastModified = heartbeatFile.lastModified();
            qint64 ageSecs = lastModified.secsTo(QDateTime::currentDateTime());
            qDebug() << "Daemon heartbeat age:" << ageSecs << "seconds";
        }
        return;  // Daemon is running, don't interfere
    }
    
    // Daemon is not running, start it
    qDebug() << "Daemon not running, starting...";
    
    // Clean up stale files before starting
    QFile::remove("/home/phablet/.daemon.pid");
    QFile::remove(HEARTBEAT_FILE);
    
    // Wait a moment for cleanup
    QThread::msleep(500);
    
    // Start daemon fresh
    startDaemon();
}
