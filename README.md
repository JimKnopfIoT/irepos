# iRepos

**The download figures of your own OpenRepos applications, on Sailfish OS.**

iRepos fetches the download counts of every application a publisher has on
[openrepos.net](https://openrepos.net) and keeps a day-by-day history on the
phone.

## What it shows

- **Any period:** the last days, weeks, months or years, or any stretch picked
  in a calendar — what it brought and from how many applications.
- **Over time:** an isometric chart of every application across the period, by
  day, week, month or year, with each application's figure beside its row.
- **Side by side:** a bar chart of the applications, every bar with its figure.
- **Per application:** version, total and what the period added, its curve,
  rating, comments and countries.
- **Signed in as the publisher:** the site's full download history and a world
  map of the countries the downloads came from.

## Privacy

- It talks to openrepos.net and nothing else. No telemetry.
- Everything fetched stays on the device.
- The OpenRepos login is kept in the device's secrets storage (Sailfish
  Secrets, encrypted and bound to the device lock). The input fields are
  emptied as soon as they are sent.

## Building

Requires the [Sailfish OS SDK](https://sailfishos.org/develop/):

```sh
mb2 -t SailfishOS-<version>-aarch64 build    # the RPM lands in RPMS/
```

On the device the package pulls in `sailfishsecretsd` and its sqlcipher
storage plugin, which hold the login.

## License

BSD 3-Clause, see [LICENSE](LICENSE). The country outlines are derived from
[Natural Earth](https://www.naturalearthdata.com/), which is in the public
domain.
