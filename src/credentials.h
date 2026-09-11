#pragma once

#include <QByteArray>
#include <QObject>
#include <QString>

// The OpenRepos login in a Sailfish Secrets collection of its own; read once at start.
class Credentials : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool stored READ stored NOTIFY changed)
    Q_PROPERTY(QString login READ login NOTIFY changed)
    // The daemon's error text; never carries anything that was kept.
    Q_PROPERTY(QString problem READ problem NOTIFY changed)

public:
    explicit Credentials(QObject *parent = nullptr);
    ~Credentials() override;

    bool stored() const;
    QString login() const;
    QString problem() const;

    Q_INVOKABLE QString password() const;
    Q_INVOKABLE bool store(const QString &login, const QString &password);
    Q_INVOKABLE bool forget();

signals:
    void changed();

private:
    void load();
    void clear();

    QString m_login;
    QByteArray m_password;
    QString m_problem;
};
