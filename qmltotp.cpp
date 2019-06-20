#include "qmltotp.h"
#include "libcppotp/bytes.h"
#include "libcppotp/otp.h"
#include <QClipboard>
#include <QGuiApplication>

QmlTotp::QmlTotp(QObject *parent) : QObject(parent)
{

}

std::string QmlTotp::normalizedBase32String(const std::string & unnorm)
{
    std::string ret;

    for (char c : unnorm)
    {
        if (c == ' ' || c == '\n' || c == '-')
        {
            // skip separators
        }
        else if (std::islower(c))
        {
            // make uppercase
            char u = std::toupper(c);
            ret.push_back(u);
        }
        else
        {
            ret.push_back(c);
        }
    }

    return ret;
}

QString QmlTotp::getTotpForSix(QString string)
{
    try {
        std::string normalizedKey = QmlTotp::normalizedBase32String(string.toUtf8().constData());
        CppTotp::Bytes::ByteString qui = CppTotp::Bytes::fromUnpaddedBase32(normalizedKey);

        uint32_t p = CppTotp::totp(qui, time(nullptr), 0, 30, 6);
        return QString::number(p);
    } catch (...) {
        return "Error";
    }
}
void QmlTotp::copyToClipboard(QString text)
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(text);
}
qlonglong QmlTotp::getTotpTime()
{
    return time(nullptr) % 30;
}
