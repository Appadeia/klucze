#ifndef QMLTOTP_H
#define QMLTOTP_H

#include <QObject>

class QmlTotp : public QObject
{
    Q_OBJECT
public:
    explicit QmlTotp(QObject *parent = nullptr);
    Q_INVOKABLE QString getTotpForSix(QString string);
    Q_INVOKABLE qlonglong getTotpTime();
    Q_INVOKABLE void copyToClipboard(QString text);
    std::string normalizedBase32String(const std::string & unnorm);

signals:

public slots:
};

#endif // QMLTOTP_H
