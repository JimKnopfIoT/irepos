# iRepos - OpenRepos download figures on the phone.

TARGET = irepos

# Version and release come from the spec; the stamp is UTC and names no host.
APP_VERSION = $$system(sed -n 's/^Version:[[:space:]]*//p' $$PWD/rpm/irepos.spec)
APP_RELEASE = $$system(sed -n 's/^Release:[[:space:]]*//p' $$PWD/rpm/irepos.spec)
BUILD_STAMP = $$system(date -u +%Y-%m-%d\ %H:%M\ UTC)
isEmpty(APP_VERSION): APP_VERSION = 0.0.0

# write_file keeps the quotes that QMAKE_SUBSTITUTES would strip.
BUILD_JS = \
    "// Written by qmake at build time - do not edit, and do not commit." \
    ".pragma library" \
    "var VERSION = \"$$APP_VERSION\"" \
    "var RELEASE = \"$$APP_RELEASE\"" \
    "var BUILT = \"$$BUILD_STAMP\""
write_file($$PWD/qml/js/Build.js, BUILD_JS)

CONFIG += sailfishapp sailfishapp_i18n

# Direct pkg-config: link_pkgconfig would drop -lsailfishapp.
QMAKE_CXXFLAGS += $$system(pkg-config --cflags sailfishsecrets)
LIBS += $$system(pkg-config --libs sailfishsecrets)

SOURCES += \
    src/irepos.cpp \
    src/credentials.cpp

HEADERS += \
    src/credentials.h

DISTFILES += \
    qml/irepos.qml \
    qml/cover/CoverPage.qml \
    qml/pages/OverviewPage.qml \
    qml/pages/AppPage.qml \
    qml/pages/PeriodDialog.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/CountriesPage.qml \
    qml/pages/CountryPage.qml \
    qml/components/qmldir \
    qml/components/Figures.qml \
    qml/components/Tint.qml \
    qml/components/Backdrop.qml \
    qml/components/StatCard.qml \
    qml/components/StepButton.qml \
    qml/components/AppRow.qml \
    qml/components/ChartDeck.qml \
    qml/components/Iso3D.qml \
    qml/components/IsoBars.qml \
    qml/components/WorldMap.qml \
    qml/components/HomeItem.qml \
    qml/components/Curve.qml \
    qml/js/Api.js \
    qml/js/Store.js \
    qml/js/Chart.js \
    qml/js/Dates.js \
    qml/js/Format.js \
    qml/js/Build.js \
    qml/js/World.js \
    irepos.desktop \
    rpm/irepos.spec

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

TRANSLATIONS += \
    translations/irepos-de.ts \
    translations/irepos-en.ts

# lupdate reads SOURCES, not DISTFILES.
lupdate_only {
    SOURCES += qml/*.qml qml/cover/*.qml qml/pages/*.qml qml/components/*.qml
}
