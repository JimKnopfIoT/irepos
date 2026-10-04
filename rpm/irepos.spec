# Keeps the build host's name out of the RPM header.
%define _buildhost reproducible-builder
Name:       irepos
Summary:    OpenRepos download figures
Version:    0.1.1
Release:    1
License:    BSD-3-Clause
URL:        https://github.com/JimKnopfIoT/irepos
Source0:    %{name}-%{version}.tar.bz2
Vendor:     irepos contributors
Packager:   irepos contributors

Requires:   sailfishsilica-qt5
# QML modules RPM does not resolve by itself.
Requires:   %{_libdir}/qt5/qml/Nemo/Configuration/qmldir
Requires:   qt5-qtdeclarative-import-localstorageplugin
# Secrets daemon and its sqlcipher storage for the login; not on every image.
Requires:   /usr/bin/sailfishsecretsd
Requires:   %{_libdir}/Sailfish/Secrets/libsailfishsecrets-sqlcipher.so

BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(sailfishsecrets)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  desktop-file-utils
BuildRequires:  qt5-qttools-linguist

%description
The download figures of your own OpenRepos applications, on the phone: the
total, what any period brought - by day, week, month or year - and which
application it came from. Signed in as the publisher, it also gets the
site's full download history and the countries the downloads came from.
Everything fetched stays on the device; the login is kept in the device's
secrets storage.

%prep
%setup -q

%build
%qmake5
%make_build

%install
%qmake5_install

%files
%defattr(-,root,root,-)
%license LICENSE
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Sun Oct 04 2026 irepos contributors 0.1.1-1
- The overview shows each application's rating: the percentage, the number
  of votes in brackets and five stars filled to the rating.
- When votes came in during the period, the change in stars stands in front
  of it: +0,1 in green, -0,1 in red.
- The rating keeps its decimals; it was rounded to a whole percent before.
- The 3D chart of every application divides the period as finely as the
  screen width allows, instead of a fixed number of columns.

* Fri Sep 11 2026 irepos contributors 0.1.0-1
- First release. The download figures of your own OpenRepos applications on
  the phone: what any period brought - days, weeks, months, years, or a
  stretch picked in a calendar - and from how many applications.
- An isometric chart of every application over the period, by day, week,
  month or year, and a bar chart of the applications side by side.
- Signed in as the publisher: the site's full download history and a world
  map of the countries the downloads came from, for any period.
- The login is kept in the device's secrets storage; everything fetched
  stays on the device.
