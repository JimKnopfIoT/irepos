#include "credentials.h"

#include <Sailfish/Secrets/createcollectionrequest.h>
#include <Sailfish/Secrets/deletesecretrequest.h>
#include <Sailfish/Secrets/result.h>
#include <Sailfish/Secrets/secret.h>
#include <Sailfish/Secrets/secretmanager.h>
#include <Sailfish/Secrets/storedsecretrequest.h>
#include <Sailfish/Secrets/storesecretrequest.h>

using namespace Sailfish::Secrets;

namespace {

// Secrets ties a collection to the binary that made it, so the renamed app needs its own.
const QString collectionName = QStringLiteral("ireposlogin");
const QString secretName = QStringLiteral("openrepos");

Secret::Identifier identifier()
{
    return Secret::Identifier(secretName,
                              collectionName,
                              SecretManager::DefaultEncryptedStoragePluginName);
}

// Only on an unshared buffer: data() detaches and would wipe a copy.
void wipe(QByteArray &bytes)
{
    if (bytes.isEmpty()) {
        return;
    }
    volatile char *raw = bytes.data();
    for (int i = 0; i < bytes.size(); ++i) {
        raw[i] = '\0';
    }
}

bool absent(const Result &result)
{
    return result.errorCode() == Result::InvalidSecretError
           || result.errorCode() == Result::InvalidCollectionError;
}

void note(const char *what, const Result &result)
{
    qWarning("iRepos: %s (%d: %s)",
             what,
             static_cast<int>(result.errorCode()),
             qPrintable(result.errorMessage()));
}

} // namespace

Credentials::Credentials(QObject *parent)
    : QObject(parent)
{
    load();
}

Credentials::~Credentials()
{
    clear();
}

bool Credentials::stored() const
{
    return !m_login.isEmpty();
}

QString Credentials::login() const
{
    return m_login;
}

QString Credentials::problem() const
{
    return m_problem;
}

QString Credentials::password() const
{
    return QString::fromUtf8(m_password);
}

void Credentials::clear()
{
    wipe(m_password);
    m_password.clear();
    m_login.clear();
}

void Credentials::load()
{
    SecretManager manager;
    StoredSecretRequest read;
    read.setManager(&manager);
    read.setIdentifier(identifier());
    // Lets secretsd ask for the device lock once per boot.
    read.setUserInteractionMode(SecretManager::SystemInteraction);
    read.startRequest();
    read.waitForFinished();
    if (read.result().code() != Result::Succeeded) {
        if (!absent(read.result())) {
            note("login not readable", read.result());
            m_problem = read.result().errorMessage();
        }
        return;
    }

    QByteArray data = read.secret().data();
    data.detach();
    // Stored as login, a zero byte, password.
    const int split = data.indexOf('\0');
    if (split > 0) {
        m_login = QString::fromUtf8(data.left(split));
        m_password = data.mid(split + 1);
    }
    wipe(data);
}

bool Credentials::store(const QString &login, const QString &password)
{
    if (login.isEmpty() || password.isEmpty()) {
        return false;
    }

    SecretManager manager;

    {
        CreateCollectionRequest create;
        create.setManager(&manager);
        create.setCollectionName(collectionName);
        create.setCollectionLockType(CreateCollectionRequest::DeviceLock);
        create.setDeviceLockUnlockSemantic(SecretManager::DeviceLockKeepUnlocked);
        create.setAccessControlMode(SecretManager::OwnerOnlyMode);
        create.setStoragePluginName(SecretManager::DefaultEncryptedStoragePluginName);
        create.setEncryptionPluginName(SecretManager::DefaultEncryptedStoragePluginName);
        create.setUserInteractionMode(SecretManager::SystemInteraction);
        create.startRequest();
        create.waitForFinished();
        if (create.result().code() != Result::Succeeded
            && create.result().errorCode() != Result::CollectionAlreadyExistsError) {
            note("secrets collection not created", create.result());
        }
    }

    {
        DeleteSecretRequest drop;
        drop.setManager(&manager);
        drop.setIdentifier(identifier());
        drop.setUserInteractionMode(SecretManager::SystemInteraction);
        drop.startRequest();
        drop.waitForFinished();
    }

    QByteArray data = login.toUtf8();
    data.append('\0');
    QByteArray secretPart = password.toUtf8();
    data.append(secretPart);
    wipe(secretPart);

    Secret secret(identifier());
    secret.setType(Secret::TypeBlob);
    secret.setData(data);
    // Our own buffer to wipe; the request's copy is out of reach.
    data.detach();

    StoreSecretRequest put;
    put.setManager(&manager);
    put.setSecretStorageType(StoreSecretRequest::CollectionSecret);
    put.setSecret(secret);
    put.setUserInteractionMode(SecretManager::SystemInteraction);
    put.startRequest();
    put.waitForFinished();
    wipe(data);

    if (put.result().code() != Result::Succeeded) {
        note("login not stored", put.result());
        m_problem = put.result().errorMessage();
        emit changed();
        return false;
    }

    clear();
    m_login = login;
    m_password = password.toUtf8();
    m_problem.clear();
    emit changed();
    return true;
}

bool Credentials::forget()
{
    SecretManager manager;
    DeleteSecretRequest drop;
    drop.setManager(&manager);
    drop.setIdentifier(identifier());
    drop.setUserInteractionMode(SecretManager::SystemInteraction);
    drop.startRequest();
    drop.waitForFinished();

    if (drop.result().code() != Result::Succeeded && !absent(drop.result())) {
        note("login not deleted", drop.result());
        m_problem = drop.result().errorMessage();
        emit changed();
        return false;
    }

    clear();
    m_problem.clear();
    emit changed();
    return true;
}
