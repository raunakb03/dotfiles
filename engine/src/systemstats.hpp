#pragma once

#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

// CPU, memory, disk and temperatures, read from /proc and /sys every `interval` ms.
//
// In QML:
//     import MyShell.Engine
//     SystemStats { running: dashboard.visible }   // only poll while someone is looking
//     ... cpuUsage, cpuTemp, memUsed, memTotal, ...
class SystemStats : public QObject {
    Q_OBJECT
    QML_ELEMENT // usable from QML as `SystemStats { }`

    // Settings (QML writes these)
    Q_PROPERTY(bool running READ running WRITE setRunning NOTIFY runningChanged)
    Q_PROPERTY(int interval READ interval WRITE setInterval NOTIFY intervalChanged)

    // Readings (read-only from QML). One NOTIFY signal for all of them: they change together.
    Q_PROPERTY(QString cpuName READ cpuName CONSTANT)
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY updated)  // 0.0 - 1.0
    Q_PROPERTY(double cpuTemp READ cpuTemp NOTIFY updated)    // °C, 0 if unknown
    Q_PROPERTY(double gpuTemp READ gpuTemp NOTIFY updated)    // °C, 0 if unknown
    Q_PROPERTY(qint64 memUsed READ memUsed NOTIFY updated)    // bytes
    Q_PROPERTY(qint64 memTotal READ memTotal NOTIFY updated)  // bytes
    Q_PROPERTY(qint64 diskUsed READ diskUsed NOTIFY updated)  // bytes, of the / filesystem
    Q_PROPERTY(qint64 diskTotal READ diskTotal NOTIFY updated)

public:
    explicit SystemStats(QObject* parent = nullptr);

    bool running() const { return m_timer.isActive(); }
    void setRunning(bool running);
    int interval() const { return m_timer.interval(); }
    void setInterval(int ms);

    QString cpuName() const { return m_cpuName; }
    double cpuUsage() const { return m_cpuUsage; }
    double cpuTemp() const { return m_cpuTemp; }
    double gpuTemp() const { return m_gpuTemp; }
    qint64 memUsed() const { return m_memUsed; }
    qint64 memTotal() const { return m_memTotal; }
    qint64 diskUsed() const { return m_diskUsed; }
    qint64 diskTotal() const { return m_diskTotal; }

    // Callable from QML: read everything now
    Q_INVOKABLE void refresh();

signals:
    void runningChanged();
    void intervalChanged();
    void updated();

private:
    void readCpu();
    void readMemory();
    void readDisk();
    void readTemperatures();
    void findSensors();

    QTimer m_timer;

    QString m_cpuName;
    double m_cpuUsage = 0;
    double m_cpuTemp = 0;
    double m_gpuTemp = 0;
    qint64 m_memUsed = 0;
    qint64 m_memTotal = 0;
    qint64 m_diskUsed = 0;
    qint64 m_diskTotal = 0;

    // CPU usage is a difference between two readings of /proc/stat
    quint64 m_lastIdle = 0;
    quint64 m_lastTotal = 0;

    // Found once: e.g. /sys/class/hwmon/hwmon5/temp1_input
    QString m_cpuTempFile;
    QString m_gpuTempFile;
};
