#include "BackupHelper.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QStandardPaths>
#include <QTextStream>
#include <QUrl>

BackupHelper::BackupHelper(QObject *parent)
    : QObject(parent)
{
}

QString BackupHelper::createBackupFile(const QString &payloadJson) const
{
    const QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QString targetDirectory = documentsPath;
    if (targetDirectory.isEmpty()) {
        targetDirectory = QDir::homePath();
    }
    if (targetDirectory.isEmpty()) {
        return QString();
    }

    QDir dir(targetDirectory);
    if (!dir.exists() && !dir.mkpath(QStringLiteral("."))) {
        return QString();
    }

    const QString timestamp = QDateTime::currentDateTime().toString(QStringLiteral("yyyyMMdd-HHmmss"));
    const QString fileName = QStringLiteral("RooTreasury-backup-%1.json").arg(timestamp);
    const QString filePath = dir.filePath(fileName);

    QFile backupFile(filePath);
    if (!backupFile.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text)) {
        return QString();
    }

    QTextStream stream(&backupFile);
    stream.setCodec("UTF-8");
    stream << payloadJson;
    backupFile.close();

    return filePath;
}

QString BackupHelper::readBackupFile(const QString &filePath) const
{
    if (filePath.trimmed().isEmpty()) {
        return QString();
    }

    QString resolvedPath = filePath;
    const QUrl fileUrl(filePath);
    if (fileUrl.isValid() && fileUrl.isLocalFile()) {
        resolvedPath = fileUrl.toLocalFile();
    }

    QFile backupFile(resolvedPath);
    if (!backupFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString();
    }

    const QByteArray fileContent = backupFile.readAll();
    backupFile.close();
    return QString::fromUtf8(fileContent);
}
