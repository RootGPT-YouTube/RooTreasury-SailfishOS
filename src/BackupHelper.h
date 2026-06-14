#ifndef BACKUPHELPER_H
#define BACKUPHELPER_H

#include <QObject>
#include <QString>

class BackupHelper : public QObject
{
    Q_OBJECT

public:
    explicit BackupHelper(QObject *parent = nullptr);
    Q_INVOKABLE QString createBackupFile(const QString &payloadJson) const;
    Q_INVOKABLE QString readBackupFile(const QString &filePath) const;
};

#endif // BACKUPHELPER_H
