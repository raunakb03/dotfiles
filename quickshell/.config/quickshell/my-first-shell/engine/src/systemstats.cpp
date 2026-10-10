#include "systemstats.hpp"

#include <QDir>
#include <QFile>
#include <QRegularExpression>
#include <QStorageInfo>

namespace {

// Read a whole (small) file, "" if it can't be read
QString readFile(const QString& path) {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(file.readAll());
}

// A hwmon temperature file holds millidegrees, e.g. "45250" = 45.25 °C
double readTemp(const QString& path) {
    bool ok = false;
    const double milli = readFile(path).trimmed().toDouble(&ok);
    return ok ? milli / 1000.0 : 0;
}

} // namespace

SystemStats::SystemStats(QObject* parent)
    : QObject(parent) {
    m_timer.setInterval(2000);
    connect(&m_timer, &QTimer::timeout, this, &SystemStats::refresh);

    // The CPU's name: the first "model name : AMD Ryzen 5 5600H with Radeon Graphics" line
    const auto cpuinfo = readFile("/proc/cpuinfo");
    const auto match = QRegularExpression("model name\\s*:\\s*(.+)").match(cpuinfo);
    if (match.hasMatch())
        m_cpuName = match.captured(1).remove(QRegularExpression("\\s+with .*$")).trimmed();

    findSensors();
    refresh();
}

void SystemStats::setRunning(bool running) {
    if (running == m_timer.isActive())
        return;
    if (running) {
        refresh(); // don't wait a whole interval for fresh numbers
        m_timer.start();
    } else {
        m_timer.stop();
    }
    emit runningChanged();
}

void SystemStats::setInterval(int ms) {
    if (ms == m_timer.interval() || ms < 100)
        return;
    m_timer.setInterval(ms);
    emit intervalChanged();
}

void SystemStats::refresh() {
    readCpu();
    readMemory();
    readDisk();
    readTemperatures();
    emit updated();
}

// /proc/stat's first line: "cpu  user nice system idle iowait irq softirq steal ..."
// (time spent in each state since boot, in ticks). Usage = 1 - idle share since the last reading.
void SystemStats::readCpu() {
    const auto line = readFile("/proc/stat").section('\n', 0, 0);
    const auto fields = line.split(' ', Qt::SkipEmptyParts);
    if (fields.size() < 5 || fields[0] != "cpu")
        return;

    quint64 total = 0;
    for (qsizetype i = 1; i < fields.size(); ++i)
        total += fields[i].toULongLong();
    const quint64 idle = fields[4].toULongLong() + (fields.size() > 5 ? fields[5].toULongLong() : 0); // idle + iowait

    const quint64 totalDiff = total - m_lastTotal;
    const quint64 idleDiff = idle - m_lastIdle;
    if (m_lastTotal > 0 && totalDiff > 0)
        m_cpuUsage = 1.0 - static_cast<double>(idleDiff) / static_cast<double>(totalDiff);

    m_lastTotal = total;
    m_lastIdle = idle;
}

// /proc/meminfo: "MemTotal: 16000000 kB", "MemAvailable: 9000000 kB", ...
// Used = total - available (available counts caches the kernel can drop).
void SystemStats::readMemory() {
    qint64 total = 0;
    qint64 available = 0;
    const auto lines = readFile("/proc/meminfo").split('\n');
    for (const auto& line : lines) {
        const auto parts = line.split(' ', Qt::SkipEmptyParts);
        if (parts.size() < 2)
            continue;
        if (parts[0] == "MemTotal:")
            total = parts[1].toLongLong() * 1024;
        else if (parts[0] == "MemAvailable:")
            available = parts[1].toLongLong() * 1024;
    }
    m_memTotal = total;
    m_memUsed = total - available;
}

void SystemStats::readDisk() {
    QStorageInfo root("/");
    root.refresh();
    m_diskTotal = root.bytesTotal();
    m_diskUsed = root.bytesTotal() - root.bytesFree(); // like df: space reserved for root isn't "used"
}

// Each /sys/class/hwmon/hwmonN has a "name" (the driver) and tempM_input files.
// CPU: k10temp (AMD) or coretemp (Intel). GPU: amdgpu, nouveau, or i915/xe.
void SystemStats::findSensors() {
    const QDir hwmon("/sys/class/hwmon");
    for (const auto& entry : hwmon.entryList(QDir::Dirs | QDir::NoDotAndDotDot)) {
        const auto dir = hwmon.filePath(entry);
        const auto name = readFile(dir + "/name").trimmed();
        const auto input = dir + "/temp1_input";
        if (!QFile::exists(input))
            continue;
        if (m_cpuTempFile.isEmpty() && (name == "k10temp" || name == "coretemp" || name == "zenpower"))
            m_cpuTempFile = input;
        else if (m_gpuTempFile.isEmpty() && (name == "amdgpu" || name == "nouveau" || name == "i915" || name == "xe"))
            m_gpuTempFile = input;
    }
}

void SystemStats::readTemperatures() {
    if (!m_cpuTempFile.isEmpty())
        m_cpuTemp = readTemp(m_cpuTempFile);
    if (!m_gpuTempFile.isEmpty())
        m_gpuTemp = readTemp(m_gpuTempFile);
}
